//
//  Animal.h
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import <Foundation/Foundation.h>
#import "TestUtils.h"

@interface Animal : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSUInteger age;

+ (void)setLogLevel:(int)level;

- (void)setName:(NSString *)name age:(NSUInteger)age;
- (NSString *)getName;
- (NSUInteger)getAge;

- (ObjStruct1)setObjStruct1:(char)a;
- (ObjStruct4)setObjStruct4:(int32_t)a;
- (ObjStruct8)setObjStruct8:(int64_t)a;
- (ObjStruct16)setObjStruct16:(int64_t)a b:(int64_t)b;
- (ObjStruct24)setObjStruct24:(int64_t)a b:(int64_t)b c:(int64_t)c;
- (ObjStruct32)setObjStruct32:(int64_t)a b:(int64_t)b c:(int64_t)c d:(int64_t)d;

@end
