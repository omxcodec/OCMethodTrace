//
//  TestUtils.h
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import <Foundation/Foundation.h>

#define TestLog(fmt, ...) NSLog((@"on %s, " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__)
