//  weibo: http://weibo.com/xiaoqing28
//  blog:  http://www.alonemonkey.com
//
//  MDMethodTrace.m
//  MonkeyDev
//
//  Created by AloneMonkey on 2017/9/6.
//  Copyright © 2017年 AloneMonkey. All rights reserved.
//

#import "OCMethodTrace.h"
#import "MDMethodTrace.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "MDConfigManager.h"

#define MDLog(fmt, ...) NSLog((@"[MethodTrace] " fmt), ##__VA_ARGS__)

@interface MDMethodTrace () <OCMethodTraceLogDelegate>

@end

@implementation MDMethodTrace : NSObject

+ (instancetype)sharedInstance {
    static MDMethodTrace *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MDMethodTrace alloc] init];
    });
    return sharedInstance;
}

+(void)addClassTrace:(NSString *)className{
    [self addClassTrace:className methodList:nil];
}

+(void)addClassTrace:(NSString *)className methodName:(NSString *)methodName{
    [self addClassTrace:className methodList:@[methodName]];
}

+(void)addClassTrace:(NSString *)className methodList:(NSArray *)methodList{
    Class targetClass = objc_getClass([className UTF8String]);
    if(targetClass != nil){
        [[OCMethodTrace getInstance] traceMethodWithClass:NSClassFromString(className) condition:^BOOL(SEL sel) {
            return (methodList == nil || methodList.count == 0) ? YES : [methodList containsObject:NSStringFromSelector(sel)];
        } before:^(id target, Class cls, SEL sel, NSArray *args, NSInteger deep) {
            NSString *selector = NSStringFromSelector(sel);
             NSMutableString *selectorString = [NSMutableString new];
            if([selector containsString:@":"]){
                NSArray *selectorArrary = [selector componentsSeparatedByString:@":"];
                selectorArrary = [selectorArrary filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]];
                for (int i = 0; i < selectorArrary.count; i++) {
                    [selectorString appendFormat:@"%@:%@ ", selectorArrary[i], args[i]];
                }
            }else{
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
            NSString *description = [MDMethodTrace targetDescription:target cls:cls];
            if ([target class] != [cls class]) {
                // 如果是子类调用基类方法，则()内打印基类名
                MDLog(@"%@%@[%@(%@) %@]", deepString, prefix, description, NSStringFromClass(cls), selectorString);
            } else {
                MDLog(@"%@%@[%@ %@]", deepString, prefix, description, selectorString);
            }
        } after:^(id target, Class cls, SEL sel, NSArray *args, NSTimeInterval interval, NSInteger deep, id retValue) {
            NSMutableString *deepString = [NSMutableString new];
            for (int i = 0; i < deep; i++) {
                [deepString appendString:@"-"];
            }
            
            NSString *prefix = target == [target class] ?  @"+" : @"-";
            MDLog(@"%@%@ret:%@", deepString, prefix, retValue);
        }];
    }else{
        MDLog(@"canot find class %@", className);
    }
}

+ (NSString *)targetDescription:(id)target cls:(Class)cls
{
    BOOL useTargetDescription = YES;
    // 过滤掉一些异常类的description方法
    if ([NSStringFromClass(cls) isEqualToString:@"__CFNotification"]) {
        useTargetDescription = NO;
    }
    return useTargetDescription ? [target description] : [NSString stringWithFormat:@"<%@: %p>", NSStringFromClass(cls), target];
}

#pragma mark - OCMethodTraceLogDelegate

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

static __attribute__((constructor)) void entry(){
    MDConfigManager * configManager = [MDConfigManager sharedInstance];
    NSDictionary* content = [configManager readConfigByKey:MDCONFIG_TRACE_KEY];
    
    [[OCMethodTrace getInstance] setLogDelegate:[MDMethodTrace sharedInstance]];
    [[OCMethodTrace getInstance] setLogLevel:OMTLogLevelDebug];
    
    if(content && [content valueForKey:MDCONFIG_ENABLE_KEY] && [content[MDCONFIG_ENABLE_KEY] boolValue]){
        NSDictionary* classListDictionary = [content valueForKey:MDCONFIG_CLASS_LIST];
        if(classListDictionary && classListDictionary.count > 0){
            for (NSString* className in classListDictionary.allKeys) {
                Class targetClass = objc_getClass([className UTF8String]);
                if(targetClass != nil){
                    id methodList = [classListDictionary valueForKey:className];
                    if([methodList isKindOfClass:[NSArray class]]){
                        [MDMethodTrace addClassTrace:className methodList:methodList];
                    }else{
                        [MDMethodTrace addClassTrace:className];
                    }
                }else{
                    MDLog(@"Canot find class %@", className);
                }
            }
        }
    }else{
        MDLog(@"Method Trace is disabled");
    }
}
