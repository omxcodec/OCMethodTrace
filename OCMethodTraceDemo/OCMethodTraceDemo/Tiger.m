//
//  Tiger.m
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import "Tiger.h"

@implementation Tiger

+ (void)setLogLevel:(int)level
{
    TestLog(@"level: %d", level);
    [super setLogLevel:level];
}

- (void)setName:(NSString *)name
{
    TestLog(@"name: %@", name);
    [super setName:name];
}

- (NSString *)getName
{
    NSString *ret = [super getName];
    TestLog(@"name: %@", ret);
    return ret;
}

- (void)setAge:(NSUInteger)age
{
    TestLog(@"age: %tu", age);
    [super setAge:age];
}

- (NSUInteger)getAge
{
    NSUInteger ret = [super getAge];
    TestLog(@"age: %tu", ret);
    return ret;
}

- (void)setName:(NSString *)name age:(NSUInteger)age
{
    TestLog(@"name: %@ age: %tu", name, age);
    [super setName:name age:age];
}

- (ObjStruct1)setObjStruct1:(char)a
{
    ObjStruct1 st = [super setObjStruct1:a];
    TestLog(@"setObjStruct1: a: %c", st.a);
    return st;
}

- (ObjStruct4)setObjStruct4:(int32_t)a
{
    ObjStruct4 st = [super setObjStruct4:a];
    TestLog(@"setObjStruct4: a: %d", st.a);
    return st;
}

- (ObjStruct8)setObjStruct8:(int64_t)a
{
    ObjStruct8 st = [super setObjStruct8:a];
    TestLog(@"setObjStruct8: a: %lld", st.a);
    return st;
}

- (ObjStruct16)setObjStruct16:(int64_t)a b:(int64_t)b
{
    ObjStruct16 st = [super setObjStruct16:a b:b];
    TestLog(@"setObjStruct16: a: %lld b: %lld", st.a, st.b);
    return st;
}

- (ObjStruct24)setObjStruct24:(int64_t)a b:(int64_t)b c:(int64_t)c
{
    ObjStruct24 st = [super setObjStruct24:a b:b c:c];
    TestLog(@"setObjStruct24: a: %lld b: %lld c: %lld", st.a, st.b, st.c);
    return st;
}

- (ObjStruct32)setObjStruct32:(int64_t)a b:(int64_t)b c:(int64_t)c d:(int64_t)d
{
    ObjStruct32 st = [super setObjStruct32:a b:b c:c d:d];
    TestLog(@"setObjStruct32: a: %lld b: %lld c: %lld d: %lld", st.a, st.b, st.c, st.d);
    return st;
}

//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"<%@: %p name: %@ age: %tu>",
//            NSStringFromClass([self class]), self, [self getName], self.age];
//}

@end
