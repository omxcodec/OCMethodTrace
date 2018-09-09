//
//  Animal.h
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import <Foundation/Foundation.h>

@interface Animal : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, assign) NSUInteger age;

+ (void)setLogLevel:(int)level;

- (void)setName:(NSString *)name age:(NSUInteger)age;
- (NSString *)getName;
- (NSUInteger)getAge;

@end
