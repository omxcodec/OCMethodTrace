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
            NSLog(@"%@[%@ %@]", deepString , target, selectorString);
        } after:^(id target, Class cls, SEL sel, NSArray *args, NSTimeInterval interval, NSInteger deep, id retValue) {
            NSMutableString *deepString = [NSMutableString new];
            for (int i = 0; i < deep; i++) {
                [deepString appendString:@"-"];
            }
            NSLog(@"%@ret:%@", deepString, retValue);
        }];
    }else{
        MDLog(@"canot find class %@", className);
    }
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
