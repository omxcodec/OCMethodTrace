/*
 * OCMethodTrace.h
 * OCMethodTrace
 *
 * https://github.com/omxcodec/OCMethodTrace
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

#import <Foundation/Foundation.h>

// 方法跟踪条件block
// @param sel 方法名
typedef BOOL (^OMTConditionBlock)(SEL sel);

// 方法调用前会调用该block
// @param target 跟踪目标对象
// @param cls 调用方法所在的类(可以是target所在的类，也可以是target的父类)
// @param sel 方法名
// @param args 参数列表
// @param deep 调用层次
typedef void (^OMTBeforeBlock)(id target, Class cls, SEL sel, NSArray *args, NSInteger deep);

// 方法调用后会调用该block
// @param target 跟踪目标对象
// @param cls 调用方法所在的类(可以是target所在的类，也可以是target的父类)
// @param sel 方法名
// @param args 参数列表
// @param interval 执行方法的ms耗时
// @param deep 调用层次
// @param retValue 返回值
typedef void (^OMTAfterBlock)(id target, Class cls, SEL sel, NSArray *args, NSTimeInterval interval, NSInteger deep, id retValue);

typedef NS_ENUM(NSUInteger, OMTLogLevel) {
    OMTLogLevelError    = 0,
    OMTLogLevelDebug    = 1,
};

@protocol OCMethodTraceLogDelegate <NSObject>

@optional
- (void)log:(OMTLogLevel)level format:(NSString *)format, ... NS_FORMAT_FUNCTION(2,3);

@end

@interface OCMethodTrace : NSObject

@property (nonatomic, weak) id<OCMethodTraceLogDelegate> logDelegate;
@property (nonatomic, assign) OMTLogLevel logLevel; // 默认OMTLogLevelDebug

+ (OCMethodTrace *)getInstance;

// 跟踪打印目标(实例或类)方法调用
// @param cls 跟踪打印目标类
// @param condition 判断是否跟踪方法的block
// @param before 被跟踪的方法调用前会调用该block
// @param after 被跟踪的方法调用后会调用该block
- (void)traceMethodWithClass:(Class)cls
                   condition:(OMTConditionBlock)condition
                      before:(OMTBeforeBlock)before
                       after:(OMTAfterBlock)after;

@end
