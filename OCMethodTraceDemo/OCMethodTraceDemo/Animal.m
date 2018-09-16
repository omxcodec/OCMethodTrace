//
//  Animal.m
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import "Animal.h"

@implementation Animal

+ (void)setLogLevel:(int)level
{
    TestLog(@"level: %d", level);
}

- (void)setName:(NSString *)name
{
    TestLog(@"name: %@", name);
    _name = name;
}

- (NSString *)getName
{
    TestLog(@"");
    return _name;
}

- (void)setAge:(NSUInteger)age
{
    TestLog(@"age: %tu", age);
    _age = age;
}

- (NSUInteger)getAge
{
    TestLog(@"");
    return _age;
}

- (void)setName:(NSString *)name age:(NSUInteger)age
{
    TestLog(@"name: %@ age: %tu", name, age);
    _name = name;
    _age = age;
}

- (ObjStruct1)setObjStruct1:(char)a
{
    TestLog(@"setObjStruct1: a: %c", a);
    
    ObjStruct1 st;
    st.a = a;
    return st;
}

- (ObjStruct4)setObjStruct4:(int32_t)a
{
    TestLog(@"setObjStruct4: a: %d", a);
    
    ObjStruct4 st;
    st.a = a;
    return st;
}

- (ObjStruct8)setObjStruct8:(int64_t)a
{
    TestLog(@"setObjStruct8: a: %lld", a);
    
    ObjStruct8 st;
    st.a = a;
    return st;
}

- (ObjStruct16)setObjStruct16:(int64_t)a b:(int64_t)b
{
    TestLog(@"setObjStruct16: a: %lld b: %lld", a, b);
    
    ObjStruct16 st;
    st.a = a;
    st.b = b;
    return st;
}

- (ObjStruct24)setObjStruct24:(int64_t)a b:(int64_t)b c:(int64_t)c
{
    TestLog(@"setObjStruct24: a: %lld b: %lld c: %lld", a, b, c);
    
    ObjStruct24 st;
    st.a = a;
    st.b = b;
    st.c = c;
    return st;
}

- (ObjStruct32)setObjStruct32:(int64_t)a b:(int64_t)b c:(int64_t)c d:(int64_t)d
{
    TestLog(@"setObjStruct32: a: %lld b: %lld c: %lld d: %lld", a, b, c, d);
    
    ObjStruct32 st;
    st.a = a;
    st.b = b;
    st.c = c;
    st.d = d;
    return st;
}

//// 问题：如果description方法里内调用已经被trace的方法，MDMethodTrace before和after输出日志时一旦调用description方法就容易出现递归死循环
//// 解决：在recursiveCallExistsAtFuncArray中判断递归，避开再次调用before和after
//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"<%@: %p name: %@ age: %tu>",
//            NSStringFromClass([self class]), self, [self getName], self.age];
//}

@end
