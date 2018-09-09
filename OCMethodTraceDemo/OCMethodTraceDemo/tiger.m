//
//  tiger.m
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import "tiger.h"
#import "TestUtils.h"

@implementation tiger

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

//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"<%@: %p name: %@ age: %tu>",
//            NSStringFromClass([self class]), self, [self getName], self.age];
//}

@end
