/*
 * OCMethodTrace.m
 * OCMethodTrace
 *
 * https://github.com/omxcodec/OCMethodTrace.git
 *
 * Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "OCMethodTrace.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <execinfo.h>
#import <dlfcn.h>
#import "imp_bridge.h"

// SEL获取IMP功能实现是否利用跳板block模式。尚未解决，暂时关闭
// #define USE_TRAMPOLINE_BLOCK_MODE

#define OMT_LOG(_level_, _fmt_, ...) do { \
        if ((_level_) <= [OCMethodTrace getInstance].logLevel) { \
            if ([OCMethodTrace getInstance].logDelegate && [[OCMethodTrace getInstance].logDelegate respondsToSelector:@selector(log:format:)]) { \
                [[OCMethodTrace getInstance].logDelegate log:OMTLogLevelDebug format:(_fmt_), ## __VA_ARGS__]; \
            } else { \
                NSLog((_fmt_), ## __VA_ARGS__); \
            } \
        } \
    } while(0)

#define OMT_LOGE(fmt, ...)  OMT_LOG(OMTLogLevelError, (fmt), ## __VA_ARGS__)
#define OMT_LOGD(fmt, ...)  OMT_LOG(OMTLogLevelDebug, (fmt), ## __VA_ARGS__)

#define ID_NOT_NIL(id) (id != nil ? id : @"nil");

static NSString *const OMTMessageTempPrefix  = @"__OMTMessageTemp_";
static NSString *const OMTMessageFinalPrefix = @"__OMTMessageFinal_";
static NSString *const OMTTraceRunBeforeSel  = @"runBefore:";
static NSString *const OMTTraceRunAfterSel   = @"runAfter:";

// 错误码，对内使用，便于调试
typedef NS_ENUM(NSUInteger, OMTErrorCode) {
    OMTErrorNoError,                        // 没有错误
    OMTErrorSelectorPassThrough,            // 透传不处理
    OMTErrorSelectorAlreadyHooked,          // 已经hook过
    OMTErrorSelectorInUserBlacklist,        // 在用户的黑名单里
    OMTErrorSelectorInSelfBlacklist,        // 在内部的黑名单里
    OMTErrorSelectorUnsuppotedType,         // 无法支持sel的编码类型
    OMTErrorDoesNotRespondToMethod,         // 无此method
    OMTErrorDoesNotRespondToSelector,       // 无此sel
    OMTErrorDoesNotRespondToIMP,            // 无此IMP
    OMTErrorSwizzleMethodFailed,            // 替换方法失败
};

#define LOG_LEVEL_4_ERROR_CODE(_errorCode_) (((_errorCode_) >= OMTErrorSelectorUnsuppotedType) ? OMTLogLevelError : OMTLogLevelDebug)

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - C Helper Define

// 替换实例方法
static void swizzle_instance_method(Class cls, SEL originSel, SEL newSel);
// 替换类方法
static void swizzle_class_method(Class cls, SEL originSel, SEL newSel);

// 是否是struct类型
static BOOL omt_isStructType(const char *argumentType);
// 获取struct类型名
static NSString *omt_structName(const char *argumentType);
// 是否是union类型
static BOOL omt_isUnionType(const char *argumentType);
// 获取union类型名
static NSString *omt_unionName(const char *argumentType);
static BOOL isCGRect           (const char *type);
static BOOL isCGPoint          (const char *type);
static BOOL isCGSize           (const char *type);
static BOOL isCGVector         (const char *type);
static BOOL isUIOffset         (const char *type);
static BOOL isUIEdgeInsets     (const char *type);
static BOOL isCGAffineTransform(const char *type);

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class Define

@interface OMTBlock : NSObject

@property (nonatomic, strong) NSString *className;
@property (nonatomic, copy) OMTConditionBlock condition;
@property (nonatomic, copy) OMTBeforeBlock before;
@property (nonatomic, copy) OMTAfterBlock after;

- (void)runBefore:(id)target class:(Class)cls sel:(SEL)sel args:(NSArray *)args deep:(NSInteger)deep;
- (void)runAfter:(id)target class:(Class)cls sel:(SEL)sel args:(NSArray *)args interval:(NSTimeInterval)interval deep:(NSInteger)deep retValue:(id)retValue;

@end

@interface OMTMessageStub : NSObject

@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic, assign) SEL selector;

- (instancetype)initWithTarget:(id)target selector:(SEL)aSelector;

@end

@interface NSObject (OCMethodTrace)
@end

@interface NSInvocation (OCMethodTrace)

// 获取方法返回值
- (id)omt_getReturnValue;
// 获取方法参数
- (NSArray *)omt_getArguments;

@end

@interface OCMethodTrace()

@property (nonatomic, strong) NSArray *defaultBlackList;
@property (nonatomic, strong) NSDictionary *supportedTypeDic;
@property (nonatomic, strong) NSMutableDictionary *blockCache;
@property (atomic, assign) NSInteger deep;

// 初始化内部默认黑名单
- (void)initDefaultBlackList;
// 初始化所支持类型编码的字典
- (void)initSupportedTypeDic;
// 根据错误码返回错误描述
+ (NSString *)errorString:(OMTErrorCode)errorCode;
// 判断是否是内部类(过滤使用)
+ (BOOL)isInternalClass:(Class)cls;
// 判断函数数组里任意函数是否存在递归调用
+ (BOOL)recursiveCallExistsAtFuncArray:(NSArray *)funcArray;
// 判断方法是否在内部默认黑名单中
- (BOOL)isSelectorInBlackList:(NSString *)methodName;
// 判断类型编码是否可以处理
- (BOOL)isSupportedType:(NSString *)typeEncode;
// block相关
- (void)setBlock:(OMTBlock *)block forKey:(NSString *)key;
- (OMTBlock *)blockforKey:(NSString *)aKey;
- (OMTBlock *)blockWithTarget:(id)target;
// 根据条件跟踪目标类的方法
- (void)traceMethodWithClass:(Class)cls condition:(OMTConditionBlock)condition;
// 判断方法是否支持跟踪
- (OMTErrorCode)isTraceSupportedWithClass:(Class)cls method:(Method)method returnType:(const char *)returnType;
// 替换方法
- (OMTErrorCode)swizzleMethodWithClass:(Class)cls originSelector:(SEL)originSelector returnType:(const char *)returnType;
// 转发实现
- (void)omt_forwardInvocation:(NSInvocation *)invocation;

@end

///////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - C Helper

static void swizzle_instance_method(Class cls, SEL originSel, SEL newSel)
{
    Method originMethod = class_getInstanceMethod(cls, originSel);
    Method newMethod = class_getInstanceMethod(cls, newSel);
    
    if (class_addMethod(cls, originSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(cls, newSel, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, newMethod);
    }
}

static void swizzle_class_method(Class cls, SEL originSel, SEL newSel)
{
    Class metaClass = objc_getMetaClass([NSStringFromClass(cls) UTF8String]);
    
    Method originMethod = class_getInstanceMethod(metaClass, originSel);
    Method newMethod = class_getInstanceMethod(metaClass, newSel);
    
    if (class_addMethod([metaClass class], originSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod([metaClass class], newSel, method_getImplementation(originMethod), method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, newMethod);
    }
}

static BOOL omt_isStructType(const char *argumentType)
{
    NSString *typeString = [NSString stringWithUTF8String:argumentType];
    return ([typeString hasPrefix:@"{"] && [typeString hasSuffix:@"}"]);
}

static NSString *omt_structName(const char *argumentType)
{
    NSString *typeString = [NSString stringWithUTF8String:argumentType];
    NSUInteger start = [typeString rangeOfString:@"{"].location;
    NSUInteger end = [typeString rangeOfString:@"="].location;
    if (end > start) {
        return [typeString substringWithRange:NSMakeRange(start + 1, end - start - 1)];
    } else {
        return nil;
    }
}

static BOOL omt_isUnionType(const char *argumentType)
{
    NSString *typeString = [NSString stringWithUTF8String:argumentType];
    return ([typeString hasPrefix:@"("] && [typeString hasSuffix:@")"]);
}

static NSString *omt_unionName(const char *argumentType)
{
    NSString *typeString = [NSString stringWithUTF8String:argumentType];
    NSUInteger start = [typeString rangeOfString:@"("].location;
    NSUInteger end = [typeString rangeOfString:@"="].location;
    if (end > start) {
        return [typeString substringWithRange:NSMakeRange(start + 1, end - start - 1)];
    } else {
        return nil;
    }
}

static BOOL isCGRect           (const char *type) {return [omt_structName(type) isEqualToString:@"CGRect"];}
static BOOL isCGPoint          (const char *type) {return [omt_structName(type) isEqualToString:@"CGPoint"];}
static BOOL isCGSize           (const char *type) {return [omt_structName(type) isEqualToString:@"CGSize"];}
static BOOL isCGVector         (const char *type) {return [omt_structName(type) isEqualToString:@"CGVector"];}
static BOOL isUIOffset         (const char *type) {return [omt_structName(type) isEqualToString:@"UIOffset"];}
static BOOL isUIEdgeInsets     (const char *type) {return [omt_structName(type) isEqualToString:@"UIEdgeInsets"];}
static BOOL isCGAffineTransform(const char *type) {return [omt_structName(type) isEqualToString:@"CGAffineTransform"];}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - OCMethodTrace

@implementation OCMethodTrace

///////////////////////////////////////////////////////////////////////////////////////////

#pragma mark - Public OCMethodTrace API

+ (OCMethodTrace *)getInstance
{
    static OCMethodTrace *instance = nil;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        instance = [[OCMethodTrace alloc] init];
    });
    return instance;
}

- (void)traceMethodWithClass:(Class)cls
                   condition:(OMTConditionBlock)condition
                      before:(OMTBeforeBlock)before
                       after:(OMTAfterBlock)after
{
#ifndef DEBUG
    return;
#endif
    
    // 内部类不跟踪
    if ([self.class isInternalClass:cls]) {
        return;
    }
    
    // 处理一个类被添加到blockCache多次的情况
    if (cls && ![self blockforKey:NSStringFromClass(cls)]) {
        OMTBlock *block = [[OMTBlock alloc] init];
        block.className = NSStringFromClass(cls);
        block.condition = condition;
        block.before = before;
        block.after = after;
        [self setBlock:block forKey:block.className];
    }
    
    // 处理实例方法
    [self traceMethodWithClass:cls condition:condition];
    
    // 处理类方法
    Class metaCls = object_getClass(cls);
    if (class_isMetaClass(metaCls)) {
        [self traceMethodWithClass:metaCls condition:condition];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private OCMethodTrace API

- (instancetype)init
{
    self = [super init];
    if (self) {
        // 参考ANYMethodLog的处理
        [self initDefaultBlackList];
        [self initSupportedTypeDic];

        self.logLevel = OMTLogLevelDebug;
        self.blockCache = [NSMutableDictionary dictionary];
        self.deep = 0;
    }
    return self;
}

- (void)dealloc
{
}

- (void)initDefaultBlackList
{
    self.defaultBlackList = @[/*UIViewController的:*/@".cxx_destruct",@"dealloc", @"_isDeallocating", @"release", @"autorelease", @"retain", @"Retain", @"_tryRetain", @"copy", /*UIView的:*/ @"nsis_descriptionOfVariable:", /*NSObject的:*/@"respondsToSelector:", @"class", @"methodSignatureForSelector:", @"allowsWeakReference", @"retainWeakReference", @"init", @"forwardInvocation:", @"description"];
}

- (void)initSupportedTypeDic
{
    self.supportedTypeDic = @{[NSString stringWithUTF8String:@encode(char)] : @"(char)",
                              [NSString stringWithUTF8String:@encode(int)] : @"(int)",
                              [NSString stringWithUTF8String:@encode(short)] : @"(short)",
                              [NSString stringWithUTF8String:@encode(long)] : @"(long)",
                              [NSString stringWithUTF8String:@encode(long long)] : @"(long long)",
                              [NSString stringWithUTF8String:@encode(unsigned char)] : @"(unsigned char))",
                              [NSString stringWithUTF8String:@encode(unsigned int)] : @"(unsigned int)",
                              [NSString stringWithUTF8String:@encode(unsigned short)] : @"(unsigned short)",
                              [NSString stringWithUTF8String:@encode(unsigned long)] : @"(unsigned long)",
                              [NSString stringWithUTF8String:@encode(unsigned long long)] : @"(unsigned long long)",
                              [NSString stringWithUTF8String:@encode(float)] : @"(float)",
                              [NSString stringWithUTF8String:@encode(double)] : @"(double)",
                              [NSString stringWithUTF8String:@encode(BOOL)] : @"(BOOL)",
                              [NSString stringWithUTF8String:@encode(void)] : @"(void)",
                              [NSString stringWithUTF8String:@encode(char *)] : @"(char *)",
                              [NSString stringWithUTF8String:@encode(id)] : @"(id)",
                              [NSString stringWithUTF8String:@encode(Class)] : @"(Class)",
                              [NSString stringWithUTF8String:@encode(SEL)] : @"(SEL)",
                              [NSString stringWithUTF8String:@encode(CGRect)] : @"(CGRect)",
                              [NSString stringWithUTF8String:@encode(CGPoint)] : @"(CGPoint)",
                              [NSString stringWithUTF8String:@encode(CGSize)] : @"(CGSize)",
                              [NSString stringWithUTF8String:@encode(CGVector)] : @"(CGVector)",
                              [NSString stringWithUTF8String:@encode(CGAffineTransform)] : @"(CGAffineTransform)",
                              [NSString stringWithUTF8String:@encode(UIOffset)] : @"(UIOffset)",
                              [NSString stringWithUTF8String:@encode(UIEdgeInsets)] : @"(UIEdgeInsets)",
                              @"@?":@"(block)", // block类型
                              }; // 添加更多类型
}

+ (NSString *)errorString:(OMTErrorCode)errorCode
{
    struct CodeToString {
        OMTErrorCode errorCode;
        const char *errorString;
    };
    static const struct CodeToString kCodeToString[] = {
        { OMTErrorNoError,                  "NERR" },
        { OMTErrorSelectorPassThrough,      "SPTH" },
        { OMTErrorSelectorAlreadyHooked,    "SAHK" },
        { OMTErrorSelectorInUserBlacklist,  "SIUB" },
        { OMTErrorSelectorInSelfBlacklist,  "SISB" },
        { OMTErrorSelectorUnsuppotedType,   "SUST" },
        { OMTErrorDoesNotRespondToMethod,   "NMTD" },
        { OMTErrorDoesNotRespondToSelector, "NSEL" },
        { OMTErrorDoesNotRespondToIMP,      "NIMP" },
        { OMTErrorSwizzleMethodFailed,      "SMDF" },
    };
    
    static const size_t kNumCodeToString = sizeof(kCodeToString) / sizeof(kCodeToString[0]);
    
    size_t i;
    for (i = 0; i < kNumCodeToString; i++) {
        if (errorCode == kCodeToString[i].errorCode) {
            break;
        }
    }
    NSAssert(i != kNumCodeToString, @"Unknown errorCode???");
    
    return [NSString stringWithUTF8String:kCodeToString[i].errorString];
}

+ (BOOL)isInternalClass:(Class)cls
{
    NSString *className = NSStringFromClass(cls);
    if ([className isEqualToString:@"OMTBlock"] ||
        [className isEqualToString:@"OMTMessageStub"] ||
        [className isEqualToString:@"OCMethodTrace"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)recursiveCallExistsAtFuncArray:(NSArray *)funcArray
{
    void *callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    BOOL exists = NO;
    // 跳过自身方法，所以从1开始
    for (int i = 1; i < frames && strs; i++) {
        NSString *frame = [NSString stringWithUTF8String:strs[i]];
        // NSLog(@"frame[%d]: %@", i, frame);
        for (NSString *func in funcArray) {
            if ([frame containsString:func]) {
                exists = YES;
                break;
            }
        }
    }
    if (strs) {
        free(strs);
    }
    return exists;
}

- (BOOL)isSelectorInBlackList:(NSString *)methodName
{
    return [self.defaultBlackList containsObject:methodName];
}

- (BOOL)isSupportedType:(NSString *)typeEncode
{
    return [self.supportedTypeDic.allKeys containsObject:typeEncode];
}

- (void)setBlock:(OMTBlock *)block forKey:(NSString *)key
{
    @synchronized (self) {
        [self.blockCache setObject:block forKey:key];
    }
}

- (OMTBlock *)blockforKey:(NSString *)key
{
    @synchronized (self) {
        return [self.blockCache objectForKey:key];
    }
}

- (OMTBlock *)blockWithTarget:(id)target
{
    @synchronized (self) {
        Class cls = [target class];
        OMTBlock *block = [self.blockCache objectForKey:NSStringFromClass(cls)];
        while (nil == block) {
            cls = [cls superclass];
            if (nil == cls) {
                break;
            }
            block = [self.blockCache objectForKey:NSStringFromClass(cls)];
        }
        
        return block;
    }
}

- (void)traceMethodWithClass:(Class)cls condition:(OMTConditionBlock)condition
{
    unsigned int outCount;
    Method *methods = class_copyMethodList(cls, &outCount);
    for (unsigned int i = 0; i < outCount; i ++) {
        Method method = *(methods + i);
        SEL selector = method_getName(method);
        char *returnType = method_copyReturnType(method);
        
        OMTErrorCode errorCode = [self isTraceSupportedWithClass:cls method:method returnType:returnType];
        if (errorCode == OMTErrorNoError && condition) {
            // 用户只有两种选择：跟踪，不跟踪
            if (!condition(selector)) {
                errorCode = OMTErrorSelectorInUserBlacklist;
            }
        }
        
        if (errorCode == OMTErrorNoError) {
            errorCode = [self swizzleMethodWithClass:cls originSelector:selector returnType:returnType];
        }
        
        OMT_LOG(LOG_LEVEL_4_ERROR_CODE(errorCode), @"[%@] hook class:%@ method:%@ types:%s",
                 [self.class errorString:errorCode],
                 NSStringFromClass(cls),
                 NSStringFromSelector(selector),
                 method_getDescription(method)->types);
        
        free(returnType);
    }
    free(methods);
}

- (OMTErrorCode)isTraceSupportedWithClass:(Class)cls method:(Method)method returnType:(const char *)returnType
{
    // 1 内部方法不处理
    NSString *selectorName = NSStringFromSelector(method_getName(method));
    if ([selectorName rangeOfString:@"omt_"].location != NSNotFound) {
        return OMTErrorSelectorPassThrough;
    }
    
    // 2 内部黑名单中的方法不处理
    if ([self isSelectorInBlackList:selectorName]) {
        return OMTErrorSelectorInSelfBlacklist;
    }
    
    // 3 处理返回值类型
    // 跳过const
    if (returnType[0] == _C_CONST) {
        returnType++;
    }
    // 支持指针类型
    if (returnType[0] != _C_PTR) {
        // struct和union有可能无法解析，但是也通过，解释不出的用?输出，便于打印函数调用链
        if (!(omt_isStructType(returnType) || omt_isUnionType(returnType))) {
            NSString *returnTypeString = [NSString stringWithUTF8String:returnType];
            if (![self isSupportedType:returnTypeString]) {
                return OMTErrorSelectorUnsuppotedType;
            }
        }
    }
    
    // 4 处理参数类型，需注意：发送消息时，第0个参数是self, 第1个参数是sel，第2个参数才是真正意义上的第一个方法参数，所以从2开始算
    for (int k = 2 ; k < method_getNumberOfArguments(method); k ++) {
        char argument[1024];
        memset(argument, 0, sizeof(argument));
        method_getArgumentType(method, k, argument, sizeof(argument));
        const char *argumentType = argument;

        // 跳过const
        if (argumentType[0] == _C_CONST) {
            argumentType++;
        }
        // 支持指针类型
        if (argumentType[0] == _C_PTR) {
            continue;
        }

        NSString *argumentString = [NSString stringWithUTF8String:argumentType];
        // struct和union有可能无法解析，但是也通过，解释不出的用?输出，便于打印函数调用链
        if (!(omt_isStructType(argumentType) || omt_isUnionType(argumentType))) {
            if (![self isSupportedType:argumentString]) {
                return OMTErrorSelectorUnsuppotedType;
            }
        }
    }

    return OMTErrorNoError;
}

- (OMTErrorCode)swizzleMethodWithClass:(Class)cls originSelector:(SEL)originSelector returnType:(const char *)returnType
{
    // 1 检查该sel是否已经hook过
    SEL newSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@->%@",
                                            OMTMessageFinalPrefix,
                                            NSStringFromClass(cls),
                                            NSStringFromSelector(originSelector)]);
    if (class_respondsToSelector(cls, newSelector)) {
        return OMTErrorSelectorAlreadyHooked;
    }
    
    // 2 原方法相关校验
    Method originMethod = class_getInstanceMethod(cls, originSelector);
    if (!originMethod) {
        return OMTErrorDoesNotRespondToMethod;
    }
    IMP originIMP = method_getImplementation(originMethod);
    if (!originIMP) {
        return OMTErrorDoesNotRespondToIMP;
    }
    const char *originTypes = method_getTypeEncoding(originMethod);

    // 3 转发：旧方法跳转到转发IMP
    // 使用比较另类的"类与方法间隔符"，如"->"。如果使用"_"，有可能会导致冲突，如系统内部类"__CFNotification"就会异常
    SEL forwardingSEL = NSSelectorFromString([NSString stringWithFormat:@"%@%@->%@",
                                              OMTMessageTempPrefix,
                                              NSStringFromClass(cls),
                                              NSStringFromSelector(originSelector)]);
#ifdef USE_TRAMPOLINE_BLOCK_MODE
    // 更简单的"imp_implementationWithBlock+内联汇编"模式
    IMP forwardingIMP = imp_implementationWithBlock(^(id object, ...) {
        // 汇编之前不要有任何改变寄存器的代码
        // TODO objc_msgSend返回值怎么透传给OC变量???
#if defined(__arm64__)
        __asm__ __volatile__(
                             "ldr x0, %0\n"
                             "ldr x1, %1\n"
                             "bl _objc_msgSend\n"
                             : /* output */
                             : "m"(object), "m"(forwardingSEL) /* input */
                             :
                             );
#endif
    });
#else
    // 参考SatanWoo的IMP桥接跳板方法
    IMP forwardingIMP = imp_selector_bridge(forwardingSEL);
#endif
    NSAssert(originIMP != forwardingIMP, @"originIMP != forwardingIMP");
    method_setImplementation(originMethod, forwardingIMP);
    
    // 4 还原：新SEL跳转回旧IMP
    if (!class_addMethod(cls, newSelector, originIMP, originTypes)) {
        return OMTErrorSwizzleMethodFailed;
    }
    
    return OMTErrorNoError;
}

- (void)omt_forwardInvocation:(NSInvocation *)invocation
{
    NSArray *argList = [invocation omt_getArguments];
    
    NSString *finalSelectorName = [NSStringFromSelector(invocation.selector) stringByReplacingOccurrencesOfString:OMTMessageFinalPrefix withString:@""];
    NSUInteger loc = [finalSelectorName rangeOfString:@"->"].location;
    NSString *originClassName = [finalSelectorName substringWithRange:NSMakeRange(0, loc)];
    NSString *originSelectorName = [finalSelectorName substringWithRange:NSMakeRange(loc + 2, finalSelectorName.length - loc - 2)];
    Class originClass = NSClassFromString(originClassName);
    SEL originSelector = NSSelectorFromString(originSelectorName);
    
    // XXX before和after回调输出日志会调用[obj description]，而description方法有可能调用类被trace的方法，最后造成递归调用。
    // 解决: 查看函数调用栈，如果发现存在OMTBlock的如下两个方法，说明就是description导致的递归调用。发现递归就跳过runBefore
    //      和runAfter调用，直接调用invoke！需要注意的是，这个查询堆栈的操作比较损失性能！
    BOOL recursiveCallExists = [self.class recursiveCallExistsAtFuncArray:@[OMTTraceRunBeforeSel, OMTTraceRunAfterSel]];
    OMTBlock *block = [self blockWithTarget:invocation.target];
    NSDate *start = nil, *end = nil;
    
    NSInteger deep = self.deep++;
    
    // 1 原方法调用前回调
    if (!recursiveCallExists) {
        [block runBefore:invocation.target class:originClass sel:originSelector args:argList deep:deep];
        start = [NSDate date];
    }
    
    // 2 调用原方法
    [invocation invoke];
    
    // 3 原方法调用后回调
    if (!recursiveCallExists) {
        end = [NSDate date];
        NSTimeInterval interval = [end timeIntervalSinceDate:start];
        [block runAfter:invocation.target class:originClass sel:originSelector args:argList interval:interval deep:deep retValue:[invocation omt_getReturnValue]];
    }
    
    self.deep--;
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - OMTBlock

@implementation OMTBlock

- (BOOL)runCondition:(SEL)sel
{
    if (self.condition) {
        return self.condition(sel);
    } else {
        return YES;
    }
}

- (void)runBefore:(id)target class:(Class)cls sel:(SEL)sel args:(NSArray *)args deep:(NSInteger)deep
{
    if (self.before) {
        self.before(target, cls, sel, args, deep);
    }
}

- (void)runAfter:(id)target class:(Class)cls sel:(SEL)sel args:(NSArray *)args interval:(NSTimeInterval)interval deep:(NSInteger)deep retValue:(id)retValue
{
    if (self.after) {
        self.after(target, cls, sel, args, interval, deep, retValue);
    }
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - OMTMessageStub

@implementation OMTMessageStub

- (instancetype)initWithTarget:(id)target selector:(SEL)aSelector
{
    self = [super init];
    if (self) {
        self.target = target;
        NSString *finalSelectorName = [NSStringFromSelector(aSelector) stringByReplacingOccurrencesOfString:OMTMessageTempPrefix withString:OMTMessageFinalPrefix];
        self.selector = NSSelectorFromString(finalSelectorName);
    }
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    Method method = class_getInstanceMethod(object_getClass(self.target), self.selector);
    if (NULL == method) {
        NSLog(@"No Method, target:%@ selector:%@", self.target, NSStringFromSelector(self.selector));
        assert(NULL != method);
    }
    
    const char *types = method_getTypeEncoding(method);
    if (NULL == types) {
        NSLog(@"No Types, target:%@ selector:%@", self.target, NSStringFromSelector(self.selector));
        assert(NULL != types);
    }
    
    return [NSMethodSignature signatureWithObjCTypes:types];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    anInvocation.target = self.target;
    anInvocation.selector = self.selector;
    
    [[OCMethodTrace getInstance] omt_forwardInvocation:anInvocation];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p target: %p selector: %@>",
            NSStringFromClass([self class]), self, self.target, NSStringFromSelector(self.selector)];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject (OCMethodTrace)

@implementation NSObject (OCMethodTrace)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swizzle_class_method([self class], @selector(forwardingTargetForSelector:), @selector(omt_forwardingTargetForSelector:));
        swizzle_instance_method([self class], @selector(forwardingTargetForSelector:), @selector(omt_forwardingTargetForSelector:));
    });
}

+ (id)omt_forwardingTargetForSelector:(SEL)aSelector
{
    if ([NSStringFromSelector(aSelector) hasPrefix:OMTMessageTempPrefix] && ![self isKindOfClass:[OMTMessageStub class]]) {
        return [[OMTMessageStub alloc] initWithTarget:self selector:aSelector];
    }
    return [self omt_forwardingTargetForSelector:aSelector];
}

- (id)omt_forwardingTargetForSelector:(SEL)aSelector
{
    if ([NSStringFromSelector(aSelector) hasPrefix:OMTMessageTempPrefix] && ![self isKindOfClass:[OMTMessageStub class]]) {
        return [[OMTMessageStub alloc] initWithTarget:self selector:aSelector];
    }
    return [self omt_forwardingTargetForSelector:aSelector];
}

@end

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSInvocation (OCMethodTrace)

@implementation NSInvocation (OCMethodTrace)

- (id)omt_getReturnValue
{
    const char *returnType = self.methodSignature.methodReturnType;
    if (returnType[0] == _C_CONST) {
        returnType++;
    }
    #define GET_RETURN_VALUE(_type) \
        if (0 == strcmp(returnType, @encode(_type))) { \
            _type val = 0; \
            [self getReturnValue:&val]; \
            return @(val); \
        }
    if (strcmp(returnType, @encode(id)) == 0 || strcmp(returnType, @encode(Class)) == 0 || strcmp(returnType, @encode(void (^)(void))) == 0) {
        __autoreleasing id returnObj;
        [self getReturnValue:&returnObj];
        return ID_NOT_NIL(returnObj);
    }
    else GET_RETURN_VALUE(char)
    else GET_RETURN_VALUE(int)
    else GET_RETURN_VALUE(short)
    else GET_RETURN_VALUE(long)
    else GET_RETURN_VALUE(long long)
    else GET_RETURN_VALUE(unsigned char)
    else GET_RETURN_VALUE(unsigned int)
    else GET_RETURN_VALUE(unsigned short)
    else GET_RETURN_VALUE(unsigned long)
    else GET_RETURN_VALUE(unsigned long long)
    else GET_RETURN_VALUE(float)
    else GET_RETURN_VALUE(double)
    else GET_RETURN_VALUE(BOOL)
    else GET_RETURN_VALUE(const char *)
    else if (strcmp(returnType, @encode(void)) == 0) {
        return @"void";
    } else if (returnType[0] == _C_PTR) {
        if (0 == strcmp(returnType, @encode(CFStringRef))) {
            void *return_temp;
            [self getReturnValue:&return_temp];
            id val = (__bridge NSString *)return_temp;
            return val;
        }
        
        // 模仿lldb bt堆栈打印形式，指针类型直接打印指针地址
        void *return_temp;
        [self getReturnValue:&return_temp];
        return [NSString stringWithFormat:@"%p", return_temp];
    } else {
        NSUInteger valueSize = 0;
        NSGetSizeAndAlignment(returnType, &valueSize, NULL);
        unsigned char valueBytes[valueSize];
        [self getReturnValue:valueBytes];
        
        return [NSValue valueWithBytes:valueBytes objCType:returnType];
    }
    return nil;
}

- (NSArray *)omt_getArguments
{
    NSMethodSignature *methodSignature = [self methodSignature];
    NSMutableArray *argList = (methodSignature.numberOfArguments > 2 ? [NSMutableArray array] : nil);
    for (NSUInteger i = 2; i < methodSignature.numberOfArguments; i++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:i];
        id arg = nil;
        
        // 跳过const
        if (argumentType[0] == _C_CONST) {
            argumentType++;
        }
        
        if (omt_isStructType(argumentType)) {
            #define GET_STRUCT_ARGUMENT(_type) \
                if (is##_type(argumentType)) { \
                    _type arg_temp; \
                    [self getArgument:&arg_temp atIndex:i]; \
                    arg = NSStringFrom##_type(arg_temp); \
                }
            GET_STRUCT_ARGUMENT(CGRect)
            else GET_STRUCT_ARGUMENT(CGPoint)
            else GET_STRUCT_ARGUMENT(CGSize)
            else GET_STRUCT_ARGUMENT(CGVector)
            else GET_STRUCT_ARGUMENT(UIOffset)
            else GET_STRUCT_ARGUMENT(UIEdgeInsets)
            else GET_STRUCT_ARGUMENT(CGAffineTransform)
            if (arg == nil) {
                arg = @"{unknown}";
            }
        }
        if (omt_isUnionType(argumentType)) {
            arg = @"(unknown)";
        }
        #define GET_ARGUMENT(_type) \
            if (0 == strcmp(argumentType, @encode(_type))) { \
                _type arg_temp; \
                [self getArgument:&arg_temp atIndex:i]; \
                arg = @(arg_temp); \
            }
        else GET_ARGUMENT(char)
        else GET_ARGUMENT(int)
        else GET_ARGUMENT(short)
        else GET_ARGUMENT(long)
        else GET_ARGUMENT(long long)
        else GET_ARGUMENT(unsigned char)
        else GET_ARGUMENT(unsigned int)
        else GET_ARGUMENT(unsigned short)
        else GET_ARGUMENT(unsigned long)
        else GET_ARGUMENT(unsigned long long)
        else GET_ARGUMENT(float)
        else GET_ARGUMENT(double)
        else GET_ARGUMENT(BOOL)
        else if (0 == strcmp(argumentType, @encode(id))) {
            __unsafe_unretained id arg_temp;
            [self getArgument:&arg_temp atIndex:i];
            arg = ID_NOT_NIL(arg_temp);
        }
        else if (0 == strcmp(argumentType, @encode(SEL))) {
            SEL arg_temp;
            [self getArgument:&arg_temp atIndex:i];
            arg = NSStringFromSelector(arg_temp);
        }
        else if (0 == strcmp(argumentType, @encode(char *))) {
            char *arg_temp;
            [self getArgument:&arg_temp atIndex:i];
            arg = [NSString stringWithUTF8String:arg_temp ? arg_temp : "NULL"];
        }
        else if (0 == strcmp(argumentType, @encode(Class))) {
            Class arg_temp;
            [self getArgument:&arg_temp atIndex:i];
            arg = arg_temp;
        }
        else if (0 == strcmp(argumentType, "@?")) {
            // 则模仿lldb bt堆栈打印形式，block类型直接打印指针地址
            if (arg == nil) {
                void *arg_temp;
                [self getArgument:&arg_temp atIndex:i];
                arg = [NSString stringWithFormat:@"%p", arg_temp];
            }
        }
        else if (argumentType[0] == _C_PTR) {
            if (0 == strcmp(argumentType, @encode(CFStringRef))) {
                void *arg_temp;
                [self getArgument:&arg_temp atIndex:i];
                arg = (__bridge NSString *)arg_temp;
            }
            // 则模仿lldb bt堆栈打印形式，指针类型直接打印指针地址
            if (nil == arg) {
                void *arg_temp;
                [self getArgument:&arg_temp atIndex:i];
                arg = [NSString stringWithFormat:@"%p", arg_temp];
            }
        }
        
        if (!arg) {
            arg = @"unknown";
        }
        [argList addObject:arg];
    }
    return argList;
}

@end
