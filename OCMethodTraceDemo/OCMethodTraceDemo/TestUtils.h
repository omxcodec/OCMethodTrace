//
//  TestUtils.h
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import <Foundation/Foundation.h>

#define TestLog(fmt, ...) NSLog((@"on %s, " fmt), __PRETTY_FUNCTION__, ##__VA_ARGS__)

typedef struct {
    char a;
} __attribute__((packed)) ObjStruct1;


typedef struct {
    int32_t a;
} __attribute__((packed)) ObjStruct4;


typedef struct {
    int64_t a;
} __attribute__((packed)) ObjStruct8;

typedef struct {
    int64_t a;
    int64_t b;
} __attribute__ ((packed)) ObjStruct16;

typedef struct {
    int64_t a;
    int64_t b;
    int64_t c;
} __attribute__ ((packed)) ObjStruct24;

typedef struct {
    int64_t a;
    int64_t b;
    int64_t c;
    int64_t d;
} __attribute__ ((packed)) ObjStruct32;
