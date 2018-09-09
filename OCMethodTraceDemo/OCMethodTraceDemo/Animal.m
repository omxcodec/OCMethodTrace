//
//  Animal.m
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import "Animal.h"
#import "TestUtils.h"

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

//// 问题：如果description方法里内调用已经被trace的方法，MDMethodTrace before和after输出日志时一旦调用description方法就容易出现递归死循环
//// 解决：在recursiveCallExistsAtFuncArray中判断递归，避开再次调用before和after
//- (NSString *)description
//{
//    return [NSString stringWithFormat:@"<%@: %p name: %@ age: %tu>",
//            NSStringFromClass([self class]), self, [self getName], self.age];
//}

@end
