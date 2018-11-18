//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  MDMethodTrace.m
//  MonkeyDev
//
//  Created by AloneMonkey on 2017/9/6.
//  Copyright © 2017年 AloneMonkey. All rights reserved.
//

#import "MDMethodTrace.h"
#import <objc/runtime.h>
#import <AVFoundation/AVFoundation.h>
#import "MDConfigManager.h"
#import "OCMethodTrace.h"

//#define USE_DDLOG // 使用外部日志系统，日志多的时候特别有用
#ifdef USE_DDLOG
#import "CocoaLumberjack.h"
static const int ddLogLevel = DDLogLevelVerbose;
#define MDLog(fmt, ...)     DDLogDebug((@"[MethodTrace] " fmt), ##__VA_ARGS__)
#else
#define MDLog(fmt, ...)     NSLog((@"[MethodTrace] " fmt), ##__VA_ARGS__)
#endif

#define SAFE_CHECK(_object, _type)  (_type *)[[self class] safeCheck:_object class:[_type class]]
#define MDFatal(fmt, ...)           [NSException raise:@"MDMethodTrace" format:fmt, ##__VA_ARGS__]

// 指定ClassInfo源
typedef NS_ENUM(NSUInteger, MDTraceSource) {
    MDTraceSourceCore   = 0,    // 引擎指定(引擎指OCMethodTrace内部实现框架)
    MDTraceSourceUser   = 1,    // 用户指定
    MDTraceSourceMerge  = 2,    // 引擎和用户合并
    MDTraceSourceMax
};

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Class Define

@interface MDTraceClassInfo : NSObject

@property (nonatomic, strong) NSString *name;       // 类名
@property (nonatomic, assign) MDTraceSource source; // 指定源
@property (nonatomic, assign) MDTraceMode mode;     // trace模式
@property (nonatomic, assign) MDTraceFlag flag;     // flag
@property (nonatomic, strong) NSMutableArray *methodList;   // 黑名单或者白名单，根据mode决定

// 解析类配置，无key则加key，设置默认值，并校验值类型
+ (instancetype)infoWithName:(NSString *)name source:(MDTraceSource)source config:(NSDictionary *)config;
// 根据类型返回引擎指定的默认ClassInfo
+ (instancetype)defaultCoreClassInfo:(NSString *)name;
// 根据类型返回用户指定的默认ClassInfo
+ (instancetype)defaultUserClassInfo:(NSString *)name;
// 安全检查
+ (id)safeCheck:(id)content class:(Class)cls;
// 数组相减: arrayA - arrayB
+ (NSArray *)minusWithArrayA:(NSArray *)arrayA arrayB:(NSArray *)arrayB;
// 数组相加: arrayA + arrayB，可去重，相同元素只保留一个
+ (NSArray *)unionWithArrayA:(NSArray *)arrayA arrayB:(NSArray *)arrayB;
// 合并引擎和用户ClassInfo，合并时core的优先级比user大，具体见函数内部实现
+ (MDTraceClassInfo *)mergeInfoWithCoreInfo:(MDTraceClassInfo *)coreInfo userInfo:(MDTraceClassInfo *)userInfo;
// 合并引擎和用户config
+ (MDTraceClassInfo *)mergeInfoWithName:(NSString *)name coreConfig:(NSDictionary *)coreConfig userConfig:(NSDictionary *)userConfig;

@end

@interface MDMethodTrace () <OCMethodTraceDelegate>

@property (nonatomic, strong) NSMutableDictionary   *config;
@property (nonatomic, assign) MDTraceLogLevel       logLevel;               // 日志级别
@property (nonatomic, assign) MDTraceLogWhen        logWhen;                // 日志输出时机
@property (nonatomic, strong) NSString              *logRegexString;        // 日志正则匹配字符串，仅当logWhen=MDTraceLogWhenRegexString有效
@property (nonatomic, assign) NSInteger             numberOfPendingLog;     // logRegexString匹配后，待输出afer日志个数
@property (nonatomic, assign) MDTraceFlag           traceFlag;              // 控制trace行为的一些特殊flag
@property (nonatomic, assign) MDTraceObject         traceObject;            // trace对象
@property (nonatomic, assign) CGFloat               lastSystemVolume;       // 上一次系统音量
@property (nonatomic, strong) NSMutableArray        *coreClassInfoList;     // 引擎类信息列表
@property (nonatomic, strong) NSMutableArray        *userClassInfoList;     // 用户类信息列表
@property (nonatomic, strong) NSMutableArray        *allClassInfoList;      // 所有类信息列表

// 解析配置文件
- (void)parseConfig:(NSDictionary *)config;

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MDTraceClassInfo

@implementation MDTraceClassInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.name = @"NoName";
        self.source = MDTraceSourceUser;
        self.mode = MDTraceModeAll;
        self.flag = MDTraceFlagDefault;
        self.methodList = [NSMutableArray array];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p name: %@ source: %tu mode: %tu flag: %tu methodList: %@>",
            NSStringFromClass([self class]), self, _name, _source, _mode, _flag, _methodList];
}

+ (instancetype)infoWithName:(NSString *)name source:(MDTraceSource)source config:(NSDictionary *)config
{
    // 无对应字典说明用户没有指定类，不处理
    if (nil == config) {
        return nil;
    }
    
    MDTraceClassInfo *info = [[MDTraceClassInfo alloc] init];
    info.name = name;
    info.source = source;
    // 1 mode
    info.mode = info.source ==  MDTraceSourceCore ? MDTraceModeOff: MDTraceModeAll;
    if (![config valueForKey:MDCONFIG_TRACE_MODE_KEY]) {
        // MDLog(@"Cannot find class %@ %@, set it to default %d", info.name, MDCONFIG_TRACE_MODE_KEY, (int)info.mode);
    } else {
        info.mode = [SAFE_CHECK(config[MDCONFIG_TRACE_MODE_KEY], NSNumber) integerValue];
    }
    
    // 2 flag
    info.flag = MDTraceFlagDefault;
    if (![config valueForKey:MDCONFIG_TRACE_FLAG_KEY]) {
        // MDLog(@"Cannot find class %@ %@, set it to default %d", info.name, MDCONFIG_TRACE_FLAG_KEY, (int)info.flag);
    } else {
        info.flag = [SAFE_CHECK(config[MDCONFIG_TRACE_FLAG_KEY], NSNumber) integerValue];
    }
    
    // 3 whiteList
    if ([config valueForKey:MDCONFIG_METHOD_WHITE_LIST_KEY]) {
        id methodList = config[MDCONFIG_METHOD_WHITE_LIST_KEY];
        if (![methodList isKindOfClass:[NSArray class]]) {
            MDFatal(@"Class %@ %@ should be array", info.name, MDCONFIG_METHOD_WHITE_LIST_KEY);
        } else if (info.mode == MDTraceModeIncludeWhiteList) {
            info.methodList = methodList;
        }
    }
    
    // 4 blackList
    if ([config valueForKey:MDCONFIG_METHOD_BLACK_LIST_KEY]) {
        id methodList = config[MDCONFIG_METHOD_BLACK_LIST_KEY];
        if (![methodList isKindOfClass:[NSArray class]]) {
            MDFatal(@"Class %@ %@ should be array", info.name, MDCONFIG_METHOD_BLACK_LIST_KEY);
        } else if (info.mode == MDTraceModeExcludeBlackList) {
            info.methodList = methodList;
        }
    }
    
    return info;
}

+ (instancetype)defaultCoreClassInfo:(NSString *)name
{
    MDTraceClassInfo *info = [[MDTraceClassInfo alloc] init];
    info.name = name;
    info.source = MDTraceSourceCore;
    info.mode = MDTraceModeOff;
    return info;
}

+ (instancetype)defaultUserClassInfo:(NSString *)name
{
    MDTraceClassInfo *info = [[MDTraceClassInfo alloc] init];
    info.name = name;
    info.source = MDTraceSourceUser;
    info.mode = MDTraceModeAll;
    return info;
}

+ (id)safeCheck:(id)content class:(Class)cls
{
    if ([content isKindOfClass:cls]) {
        return content;
    }
    MDFatal(@"safeCheck failed, content(%@) should be class(%@) type", content, NSStringFromClass(cls));
    return nil;
}

+ (NSArray *)minusWithArrayA:(NSArray *)arrayA arrayB:(NSArray *)arrayB
{
    NSMutableOrderedSet *setA = [NSMutableOrderedSet orderedSetWithArray:arrayA];
    NSMutableOrderedSet *setB = [NSMutableOrderedSet orderedSetWithArray:arrayB];
    [setA minusOrderedSet:setB];
    return [setA array];
}

+ (NSArray *)unionWithArrayA:(NSArray *)arrayA arrayB:(NSArray *)arrayB
{
    NSMutableOrderedSet *setA = [NSMutableOrderedSet orderedSetWithArray:arrayA];
    NSMutableOrderedSet *setB = [NSMutableOrderedSet orderedSetWithArray:arrayB];
    [setA unionOrderedSet:setB];
    return [setA array];
}

- (void)setSource:(MDTraceSource)source
{
    NSAssert(source >= MDTraceSourceCore && source < MDTraceSourceMax, @"invalid TraceSource");
    _source = source;
}

- (void)setMode:(MDTraceMode)mode
{
    NSAssert(mode >= MDTraceModeOff && mode < MDTraceModeMax, @"invalid TraceMode");
    _mode = mode;
}

- (void)setFlag:(MDTraceFlag)flag
{
    NSAssert(flag >= MDTraceModeOff && flag <= MDTraceFlagMask, @"invalid TraceFlag");
    _flag = flag;
}

- (id)copyWithZone:(NSZone *)zone
{
    MDTraceClassInfo *info = [[self.class allocWithZone:zone] init];
    
    info.name = self.name;
    info.source = self.source;
    info.mode = self.mode;
    info.flag = self.flag;
    info.methodList = [NSMutableArray arrayWithArray:self.methodList];
    
    return info;
}

+ (MDTraceClassInfo *)mergeInfoWithCoreInfo:(MDTraceClassInfo *)coreInfo userInfo:(MDTraceClassInfo *)userInfo
{
    if (nil == coreInfo && nil == userInfo) {
        NSAssert(0, @"invalid info");
        return nil;
    }
    
    MDTraceClassInfo *mergeInfo = nil;
    if (nil != coreInfo && nil == userInfo) {
        NSAssert(coreInfo.source == MDTraceSourceCore, @"invalid core source");
        mergeInfo = [coreInfo copy];
    } else if (nil == coreInfo && nil != userInfo) {
        NSAssert(userInfo.source == MDTraceSourceUser, @"invalid user source");
        mergeInfo = [userInfo copy];
    } else {
        NSAssert([coreInfo.name isEqualToString:userInfo.name], @"invalid name");
        NSAssert(coreInfo.source == MDTraceSourceCore, @"invalid core source");
        NSAssert(coreInfo.mode == MDTraceModeOff || coreInfo.mode == MDTraceModeExcludeBlackList, @"invalid core mode");
        NSAssert(userInfo.source == MDTraceSourceUser, @"invalid user source");
        
        mergeInfo = [[MDTraceClassInfo alloc] init];
        mergeInfo.name = coreInfo.name;
        mergeInfo.source = MDTraceSourceMerge;
        mergeInfo.flag = coreInfo.flag | userInfo.flag;
        // core优先级比user优先级高
        if (coreInfo.mode == MDTraceModeOff) {
            // core关闭则无需关心user配置
            mergeInfo.mode = MDTraceModeOff;
        } else if (coreInfo.mode == MDTraceModeExcludeBlackList) {
            switch (userInfo.mode) {
                case MDTraceModeOff:
                    // user关闭就不trace这个类
                    mergeInfo.mode = MDTraceModeOff;
                    break;
                case MDTraceModeAll:
                    // 排除core指定的黑名单
                    mergeInfo.mode = MDTraceModeExcludeBlackList;
                    [mergeInfo.methodList addObjectsFromArray:coreInfo.methodList];
                    break;
                case MDTraceModeIncludeWhiteList:
                    // user白名单排除掉core黑名单
                    mergeInfo.mode = MDTraceModeIncludeWhiteList;
                    [mergeInfo.methodList addObjectsFromArray:[[self class] minusWithArrayA:userInfo.methodList arrayB:coreInfo.methodList]];
                    break;
                case MDTraceModeExcludeBlackList:
                    // user黑名单加上core黑名单
                    mergeInfo.mode = MDTraceModeExcludeBlackList;
                    [mergeInfo.methodList addObjectsFromArray:[[self class] unionWithArrayA:userInfo.methodList arrayB:coreInfo.methodList]];
                    break;
                default:
                    break;
            }
        }
    }

    return mergeInfo;
}

+ (MDTraceClassInfo *)mergeInfoWithName:(NSString *)name coreConfig:(NSDictionary *)coreConfig userConfig:(NSDictionary *)userConfig;
{
    MDTraceClassInfo *coreInfo = [MDTraceClassInfo infoWithName:name source:MDTraceSourceCore config:coreConfig];
    MDTraceClassInfo *userInfo = [MDTraceClassInfo infoWithName:name source:MDTraceSourceUser config:userConfig];
    return [MDTraceClassInfo mergeInfoWithCoreInfo:coreInfo userInfo:userInfo];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MDMethodTrace

@implementation MDMethodTrace

+ (instancetype)sharedInstance {
    static MDMethodTrace *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MDMethodTrace alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.logLevel           = MDTraceLogLeveDebug;
        self.logWhen            = MDTraceLogWhenStartup;
        self.traceFlag          = MDTraceFlagDefault;
        self.traceObject        = MDTraceObjectNone;
        self.coreClassInfoList  = [[NSMutableArray alloc] init];
        self.userClassInfoList  = [[NSMutableArray alloc] init];
        self.allClassInfoList   = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
#if !TARGET_OS_SIMULATOR
    [self removeVolumeObserver];
#endif
}

#pragma mark - Trace utils

+ (NSString *)docPath
{
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
}

// 安全检查
+ (id)safeCheck:(id)content class:(Class)cls
{
    if ([content isKindOfClass:cls]) {
        return content;
    }
    MDFatal(@"safeCheck failed, content(%@) should be class(%@) type", content, NSStringFromClass(cls));
    return nil;
}

// 正则匹配
// FIXME -[NSString rangeOfString:options:NSRegularExpressionSearch]在实际运行中会死循环，不太明白原因
+ (BOOL)isMatchRegexString:(NSString *)regexString inputString:(NSString *)inputString
{
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:inputString options:0 range:NSMakeRange(0, [inputString length])];
    return nil != result;
}

// 判断是否是构造函数(实现比较粗犷，不是特别准确)
+ (BOOL)isConstructorWithTarget:(id)target selector:(SEL)selector
{
    NSString *selectorName = NSStringFromSelector(selector);
    if (![selectorName containsString:@"init"]) {
        return NO;
    }
    
    Method method = class_getInstanceMethod(object_getClass(target), selector);
    if (NULL == method) {
        MDLog(@"No Method, target: %@ selector: %@", [target class], NSStringFromSelector(selector));
        assert(NULL != method);
    }
    
    char returnType[1024];
    memset(returnType, 0, sizeof(returnType));
    method_getReturnType(method, returnType, sizeof(returnType));
    return (0 == strcmp(returnType, @encode(id)));
}

// 获取object名称
+ (NSString *)NSStringFromTraceObject:(MDTraceObject)traceObject
{
    NSString *name;
    switch (traceObject) {
        case MDTraceObjectNone:
            name = @"未指定类";
            break;
        case MDTraceObjectUserClass:
            name = @"用户类";
            break;
        case MDTraceObjectCoreClass:
            name = @"引擎类";
            break;
        case MDTraceObjectAllClass:
            name = @"引擎+用户类";
            break;
        default:
            NSAssert1(0, @"Unkown trace object: %tu", traceObject);
            break;
    }
    
    return name;
}

// 判断object是否属于测试模式
+ (BOOL)isTestTraceObject:(MDTraceObject)traceObject
{
    return (traceObject == MDTraceObjectCoreClass || traceObject == MDTraceObjectAllClass);
}

// 获取当前classInfoList
- (NSArray *)classInfoList
{
    if (self.traceObject == MDTraceObjectUserClass) {
        return self.userClassInfoList;
    } else if (self.traceObject == MDTraceObjectCoreClass) {
        return self.coreClassInfoList;
    } else if (self.traceObject == MDTraceObjectAllClass) {
        return self.allClassInfoList;
    }
    return nil;
}

// 查找某个类是否存在classInfoList中
- (MDTraceClassInfo *)infoInClassInfoList:(NSString *)className
{
    for (MDTraceClassInfo *info in [self classInfoList]) {
        if ([info.name isEqualToString:className]) {
            return info;
        }
    }
    return nil;
}

// dump输出ClassListInfo
- (void)dumpClassListInfo
{
    if (!(self.traceFlag & MDTraceFlagDumpClassListInfo)) {
        return;
    }
    
    MDLog(@"Dump %@ class list info: ", [[self class] NSStringFromTraceObject:self.traceObject]);
    MDLog(@"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    NSArray *classInfoList = [self classInfoList];
    for (int i = 0; i < classInfoList.count; i++) {
        MDLog(@"ClassList[%05d]: %@", i, classInfoList[i]);
    }
    MDLog(@"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
}

// dump类所有方法信息
- (void)dumpClassMethodInfo:(MDTraceClassInfo *)classInfo
{
    if (!(self.traceFlag & MDTraceFlagDumpClassMethod || classInfo.flag & MDTraceFlagDumpClassMethod)) {
        return;
    }
    
    MDLog(@"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
    
    Class cls = NSClassFromString(classInfo.name);
    while (nil != cls) {
        unsigned int numMethods = 0;
        Method *methodList = class_copyMethodList(cls, &numMethods);
        if (NULL != methodList) {
            for (unsigned int i = 0; i < numMethods; i ++) {
                MDLog(@"-Class[%@] method[%03d]: %@", cls, i, [[self class] methodInfo:methodList[i]]);
            }
        }
        
        Class metaClass = object_getClass(cls);
        methodList = class_copyMethodList(metaClass, &numMethods);
        if (NULL != methodList) {
            for (unsigned int i = 0; i < numMethods; i ++) {
                MDLog(@"+Class[%@] method[%03d]: %@", cls, i, [[self class] methodInfo:methodList[i]]);
            }
        }
        
        if (!(self.traceFlag & MDTraceFlagDumpSuperClassMethod || classInfo.flag & MDTraceFlagDumpSuperClassMethod)) {
            break;
        }
        cls = [cls superclass];
    }
    
    MDLog(@"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
}

// 某方法信息
+ (NSString *)methodInfo:(Method)method
{
    return [NSString stringWithFormat:@"name[%s] IMP[%p]", sel_getName(method_getName(method)), method_getImplementation(method)];
}

#pragma mark - Trace log

// 初始化日志系统
- (void)initLogger
{
#ifdef USE_DDLOG
    // 外部Lumberjack logger, 日志存放于目录"~/Library/Caches/Logs"
    [DDLog addLogger:[DDTTYLogger sharedInstance]]; // TTY = Xcode 控制台
    // [[DDTTYLogger sharedInstance] setColorsEnabled:YES];
    // [DDLog addLogger:[DDASLLogger sharedInstance]]; // ASL = Apple System Logs 苹果系统日志
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init]; // 本地文件日志
    fileLogger.doNotReuseLogFiles = YES;
    fileLogger.logFileManager.maximumNumberOfLogFiles = 1; // 永远创建一个文件，便于观察日志
    fileLogger.maximumFileSize = 0;
    fileLogger.rollingFrequency = 0;
    [DDLog addLogger:fileLogger];
#endif
    
    // 内部logger
    [[OCMethodTrace sharedInstance] setLogLevel:self.logLevel == MDTraceLogLeveError ? OMTLogLevelError : OMTLogLevelDebug];
    [[OCMethodTrace sharedInstance] setDelegate:self];
}

// trace开关
- (void)enableTrace:(BOOL)enable
{
    if (!enable) {
        [OCMethodTrace sharedInstance].disableTrace = YES;
    } else {
        if (self.logWhen == MDTraceLogWhenVolume) {
#if TARGET_OS_SIMULATOR
            [OCMethodTrace sharedInstance].disableTrace = NO;
            self.logWhen = MDTraceLogWhenStartup;
            MDLog(@"Volume control log is not supported when simulator, reset logWhen to %tu", self.logWhen);
#else
            self.lastSystemVolume = [[AVAudioSession sharedInstance] outputVolume];
            // 需要异步注册通知，否则无法工作
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addVolumeObserver];
            });
#endif
        } else {
            [OCMethodTrace sharedInstance].disableTrace = NO;
        }
    }
}

#if !TARGET_OS_SIMULATOR
- (void)addVolumeObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onSystemVolumeChanged:) name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)removeVolumeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                  object:nil];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}

- (void)onSystemVolumeChanged:(NSNotification *)notification
{
    NSString *category = notification.userInfo[@"AVSystemController_AudioCategoryNotificationParameter"];
    NSString *changeReason = notification.userInfo[@"AVSystemController_AudioVolumeChangeReasonNotificationParameter"];
    if (![category isEqualToString:@"Audio/Video"] || ![changeReason isEqualToString:@"ExplicitVolumeChange"]) {
        return;
    }
    CGFloat volume = [[notification userInfo][@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    [OCMethodTrace sharedInstance].disableTrace = volume < self.lastSystemVolume; // 音量升高触发日志输出
    self.lastSystemVolume = volume;
}
#endif

#pragma mark - Trace parse config

- (void)parseConfig:(NSDictionary *)config
{
    if (nil == config) {
        return;
    }
    
    MDLog(@" ");
    MDLog(@"////////////////////////////////////////////////////////////////////////////////");
    MDLog(@"// Usage: https://github.com/omxcodec/OCMethodTrace/blob/master/README.md");
    MDLog(@"////////////////////////////////////////////////////////////////////////////////");
    MDLog(@" ");
    
    self.config         = [NSMutableDictionary dictionaryWithDictionary:config];
    self.logLevel       = [SAFE_CHECK(self.config[MDCONFIG_LOG_LEVEL_KEY], NSNumber) unsignedIntegerValue];
    self.logWhen        = [SAFE_CHECK(self.config[MDCONFIG_LOG_WHEN_KEY], NSNumber) unsignedIntegerValue];
    self.traceFlag      = [SAFE_CHECK(self.config[MDCONFIG_TRACE_FLAG_KEY], NSNumber) unsignedIntegerValue];
    self.traceObject    = [SAFE_CHECK(self.config[MDCONFIG_TRACE_OBJECT_KEY], NSNumber) unsignedIntegerValue];
    
    MDLog(@"logLevel: %tu: logWhen: %tu traceFlag: %tu traceObject: %tu(%@%@)",
          self.logLevel, self.logWhen, self.traceFlag, self.traceObject,
          [[self class] NSStringFromTraceObject:self.traceObject],
          [[self class] isTestTraceObject:self.traceObject] ? @"(仅测试验证使用，不建议开启)" : @"");
    
    NSAssert(self.logLevel >= MDTraceLogLeveError && self.logLevel < MDTraceLogLeveMax, @"invalid loglevel");
    NSAssert(self.logWhen >= MDTraceLogWhenStartup && self.logWhen < MDTraceLogWhenMax, @"invalid logWhen");
    NSAssert(self.traceFlag >= 0 && self.traceFlag <= MDTraceFlagMask, @"invalid traceFlag");
    NSAssert(self.traceObject >= MDTraceObjectNone && self.traceObject < MDTraceObjectMax, @"invalid traceObject");
    
    if (self.logWhen == MDTraceLogWhenRegexString) {
        self.logRegexString = SAFE_CHECK(config[MDCONFIG_LOG_REGEX_STRING_KEY], NSString);
        if (self.logRegexString.length == 0) {
            MDFatal(@"logRegexString is nil");
        }
        MDLog(@"logRegexString: %@", self.logRegexString);
    }
    
    [self initLogger];
    
    // 屏蔽trace输出。避免hook准备过程中导致的递归调用
    [self enableTrace:NO];
    
    [self traceClassObject];
    
    // 恢复trace输出
    [self enableTrace:YES];
}

- (void)traceClassObject
{
    if (self.traceObject == MDTraceObjectNone) {
        MDLog(@"Method Trace is disabled");
        return;
    }
    
    [self parseClassListInfo];
    [self dumpClassListInfo];
    [self traceClassListInfo];
}
   
- (void)traceClassListInfo
{
    MDLog(@" ");
    MDLog(@"////////////////////////////////////////////////////////////////////////////////");
    MDLog(@" ");
    
    if (self.traceObject == MDTraceObjectAllClass) {
        int numberOfClasses = objc_getClassList(NULL, 0);
        MDLog(@"numberOfClasses: %d", numberOfClasses);
        Class *classList = (Class *)malloc(sizeof(Class) * numberOfClasses);
        if (NULL != classList) {
            objc_getClassList(classList, numberOfClasses);
            for (int i = 0; i < numberOfClasses; i++) {
                NSString *className = NSStringFromClass(classList[i]);
                MDTraceClassInfo *coreClassInfo = [self infoInClassInfoList:className];
                // methodList调试时经常修改方法列表，这里总是尝试trace验证
                if ((nil != coreClassInfo && coreClassInfo.mode != MDTraceModeOff) || nil == coreClassInfo) {
                    MDLog(@"[TEST] trace ClassList[%05d]: %@", i, className);
                    if (nil != coreClassInfo) {
                        [self traceClass:coreClassInfo];
                    } else {
                        [self traceClass:[MDTraceClassInfo defaultUserClassInfo:className]];
                    }
                }
            }
            free(classList);
        }
    } else if (self.traceObject == MDTraceObjectUserClass || self.traceObject == MDTraceObjectCoreClass) {
        NSArray *classInfoList = [self classInfoList];
        for (int i = 0; i < classInfoList.count; i++) {
            MDTraceClassInfo *info = classInfoList[i];
            if (nil != objc_getClass([info.name UTF8String])) {
                MDLog(@"ClassList[%05d]: %@", i, info.name);
                [self traceClass:info];
            } else {
                MDLog(@"Cannot find class %@", info.name);
            }
        }
    }
    
    MDLog(@" ");
    MDLog(@"////////////////////////////////////////////////////////////////////////////////");
    MDLog(@" ");
}

- (void)parseClassListInfo
{
    id object = nil;
    NSDictionary *coreClassListDict = nil;
    NSDictionary *userClassListDict = nil;
    
    object = [self.config valueForKey:MDCONFIG_CORE_CLASS_LIST];
    if (nil != object) {
        coreClassListDict = SAFE_CHECK(object, NSDictionary);
    }
    object = [self.config valueForKey:MDCONFIG_USER_CLASS_LIST];
    if (nil != object) {
        userClassListDict = SAFE_CHECK(object, NSDictionary);
    }
    
    // core
    if (self.traceObject == MDTraceObjectCoreClass) {
        for (NSString *className in coreClassListDict.allKeys) {
            NSDictionary *coreConfig = coreClassListDict[className];
            MDTraceClassInfo *coreInfo = [MDTraceClassInfo infoWithName:className source:MDTraceSourceCore config:coreConfig];
            [self.coreClassInfoList addObject:coreInfo];
        }
    }

    // user，注意，user需要跟core合并，core优先级更高
    if (self.traceObject == MDTraceObjectUserClass || self.traceObject == MDTraceObjectAllClass) {
        for (NSString *className in userClassListDict.allKeys) {
            NSDictionary *coreConfig = coreClassListDict[className];
            NSDictionary *userConfig = userClassListDict[className];
            MDTraceClassInfo *mergeinfo = [MDTraceClassInfo mergeInfoWithName:className coreConfig:coreConfig userConfig:userConfig];
            [self.userClassInfoList addObject:mergeinfo];
        }
    }
    
    // all
    if (self.traceObject == MDTraceObjectAllClass) {
        // 添加user已经解析出来的Info
        [self.allClassInfoList addObjectsFromArray:self.userClassInfoList];
        
        // 另外有可能core还有一些类不在user列表里，需要另外添加
        for (NSString *className in coreClassListDict.allKeys) {
            if (nil == [self infoInClassInfoList:className]) {
                NSDictionary *coreConfig = coreClassListDict[className];
                MDTraceClassInfo *coreInfo = [MDTraceClassInfo infoWithName:className source:MDTraceSourceCore config:coreConfig];
                [self.allClassInfoList addObject:coreInfo];
            }
        }
    }
}

- (void)traceClass:(MDTraceClassInfo *)classInfo
{
    if (nil == classInfo) {
        return;
    }
    
    [self dumpClassMethodInfo:classInfo];
    
    if (classInfo.mode == MDTraceModeOff) {
    } else if (classInfo.mode == MDTraceModeAll) {
        [self addClassTrace:classInfo.name];
    } else if (classInfo.mode == MDTraceModeIncludeWhiteList) {
        [self addClassTrace:classInfo.name methodList:classInfo.methodList white:YES];
    } else if (classInfo.mode == MDTraceModeExcludeBlackList) {
        [self addClassTrace:classInfo.name methodList:classInfo.methodList white:NO];
    }
    
    [self dumpClassMethodInfo:classInfo];
}

#pragma mark - Trace method

- (void)addClassTrace:(NSString *)className{
    [self addClassTrace:className methodList:nil];
}

- (void)addClassTrace:(NSString *)className methodName:(NSString *)methodName {
    [self addClassTrace:className methodList:@[methodName]];
}

- (void)addClassTrace:(NSString *)className methodList:(NSArray*)methodList {
    [self addClassTrace:className methodList:methodList white:YES];
}

- (void)addClassTrace:(NSString *)className methodList:(NSArray *)methodList white:(BOOL)white {
    Class targetClass = objc_getClass([className UTF8String]);
    if (targetClass != nil) {
        [[OCMethodTrace sharedInstance] traceMethodWithClass:NSClassFromString(className) condition:^BOOL(SEL sel) {
            if (methodList == nil || methodList.count == 0) {
                return YES;
            }
            for (id object in methodList) {
                NSString *methodName = SAFE_CHECK(object, NSString);
                // 方法可以是正则表达式
                if ([[self class] isMatchRegexString:methodName inputString:NSStringFromSelector(sel)]) {
                    return white;
                }
            }
            return !white;
        } before:^(id target, Class cls, SEL sel, NSArray *args, int deep) {
            NSString *selector = NSStringFromSelector(sel);
            NSMutableString *selectorString = [NSMutableString new];
            if ([selector containsString:@":"]) {
                NSArray *selectorArrary = [selector componentsSeparatedByString:@":"];
                selectorArrary = [selectorArrary filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
                for (int i = 0; i < selectorArrary.count; i++) {
                    [selectorString appendFormat:@"%@:%@ ", selectorArrary[i], args[i]];
                }
            } else {
                [selectorString appendString:selector];
            }
           
            NSMutableString *deepString = [NSMutableString new];
            for (int i = 0; i < deep; i++) {
                [deepString appendString:@"-"];
            }
            
            // [obj class]则分两种情况：
            // 1 当obj为实例对象时，[obj class]中class是实例方法：- (Class)class，返回的obj对象中的isa指针；
            // 2 当obj为类对象（包括元类和根类以及根元类）时，调用的是类方法：+ (Class)class，返回的结果为其本身。
            NSString *prefix = target == [target class] ?  @"+" : @"-";
            // target不是强引用，如果打印接口异步，可能未实际调用description就被释放了，所以提前获取desc，保证线程安全
            NSString *description = [self descriptionWithTarget:target selector:sel returnState:NO];
            NSString *logString = nil;
            if ([target class] != [cls class]) {
                // 如果是子类调用基类方法，则()内打印基类名
                logString = [NSString stringWithFormat:@"%@%@[%@(%@) %@]", deepString, prefix, description, NSStringFromClass(cls), selectorString];
            } else {
                logString = [NSString stringWithFormat:@"%@%@[%@ %@]", deepString, prefix, description, selectorString];
            }
            
            if (self.logWhen == MDTraceLogWhenStartup ||
                self.logWhen == MDTraceLogWhenVolume ||
                (self.logWhen == MDTraceLogWhenRegexString && [[self class] isMatchRegexString:self.logRegexString inputString:logString])) {
                self.numberOfPendingLog++;
                MDLog("%@", logString);
            }
        } after:^(id target, Class cls, SEL sel, id ret, int deep, NSTimeInterval interval) {
            // 因为多线程并发，numberOfPendingLog变量维护的输出状态有可能并不是那么准，但是打印调试可以容忍
            if (self.numberOfPendingLog > 0) {
                self.numberOfPendingLog--;
                NSMutableString *deepString = [NSMutableString new];
                for (int i = 0; i < deep; i++) {
                    [deepString appendString:@"-"];
                }
            
                NSString *prefix = target == [target class] ?  @"+" : @"-";
                MDLog(@"%@%@ret:%@", deepString, prefix, ret);
            }
        }];
    } else {
        MDLog(@"Canot find class %@", className);
    }
}

#pragma mark - OCMethodTraceDelegate

- (NSString *)descriptionWithTarget:(id)target selector:(SEL)selector returnState:(BOOL)returnState
{
    if (nil == target) {
        return @"nil";
    }
    
    // 调用构造函数时因为target还没初始化完全，建议before时先不调用description(after时可以调用)
    NSString *className = NSStringFromClass([target class]);
    
    // 全局跳过对象description方法
    if (self.traceFlag & MDTraceFlagDoesNotUseDescription) {
        return [NSString stringWithFormat:@"<%@: %p>", className, target];
    }
    
    // 类跳过对象description方法，粒度更小一点
    MDTraceClassInfo *info = [self infoInClassInfoList:className];
    BOOL doesNotUseDescription = (nil != info && info.flag & MDTraceFlagDoesNotUseDescription);
    if (!doesNotUseDescription) {
        // 当执行initXXX等构造函数，进入before回调时(before指非返回状态，after指返回状态)，因为实例对象并没有初始化完成，所以，此时不要调用target的description方法
        doesNotUseDescription = !returnState && [[self class] isConstructorWithTarget:target selector:selector];
    }
    return doesNotUseDescription ? [NSString stringWithFormat:@"<%@: %p>", className, target] : [target description];
}

- (void)log:(OMTLogLevel)level format:(NSString *)format, ...
{
    va_list args;
    if (format) {
        va_start(args, format);
        NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
        va_end(args);
        
        MDLog(@"%@", message);
    }
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Entry

static __attribute__((constructor)) void entry()
{
    NSDictionary *config = [[MDConfigManager sharedInstance] readConfigByKey:MDCONFIG_TRACE_KEY];
    [[MDMethodTrace sharedInstance] parseConfig:config];
}
