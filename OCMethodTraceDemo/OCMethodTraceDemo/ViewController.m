//
//  ViewController.m
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import "ViewController.h"
#import "tiger.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // insert code here...
    NSLog(@"Hello, OCMethodTrace!");
    
    NSLog(@" ");
    NSLog(@"==============================");
    NSLog(@"tiger setLogLevel:");
    [tiger setLogLevel:1];
    NSLog(@"==============================");
    NSLog(@" ");
    
    tiger *obj = [[tiger alloc] init];

    NSString *name = nil;
    NSUInteger age = 0;
    
    ///////////////////////////////////////////////////////////////
    
    NSLog(@" ");
    NSLog(@"==============================");
    NSLog(@"tiger setName:age:");
    [obj setName:@"Tiger-0" age:5];
    NSLog(@"==============================");
    NSLog(@" ");

    NSLog(@" ");
    NSLog(@"==============================");
    name = [obj getName];
    NSLog(@"tiger name: %@", name);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    age = [obj getAge];
    NSLog(@"tiger age: %tu", age);
    NSLog(@"==============================");
    NSLog(@" ");
    
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct1 st1 = [obj setObjStruct1:'a'];
    NSLog(@"tiger setObjStruct1: a: %c", st1.a);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct4 st4 = [obj setObjStruct4:1];
    NSLog(@"tiger setObjStruct4: a: %d", st4.a);
    NSLog(@"==============================");
    NSLog(@" ");
    
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct8 st8 = [obj setObjStruct8:1];
    NSLog(@"tiger setObjStruct8: a: %lld", st8.a);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct16 st16 = [obj setObjStruct16:1 b:2];
    NSLog(@"tiger setObjStruct16: a: %lld b: %lld", st16.a, st16.b);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct24 st24 = [obj setObjStruct24:1 b:2 c:3];
    NSLog(@"tiger setObjStruct24: a: %lld b: %lld b: %lld", st24.a, st24.b, st24.c);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct32 st32 = [obj setObjStruct32:1 b:2 c:3 d:4];
    NSLog(@"tiger setObjStruct32: a: %lld b: %lld c: %lld d: %lld", st32.a, st32.b, st32.c, st32.d);
    NSLog(@"==============================");
    NSLog(@" ");
    
    ///////////////////////////////////////////////////////////////
    
    NSLog(@" ");
    NSLog(@"==============================");
    NSLog(@"tiger setName:");
    [obj setName:@"Tiger-1"];
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    name = [obj getName];
    NSLog(@"tiger name: %@", name);
    NSLog(@"==============================");
    NSLog(@" ");
    
    ///////////////////////////////////////////////////////////////
    
    NSLog(@" ");
    NSLog(@"==============================");
    NSLog(@"tiger setAge:");
    [obj setAge:10];
    NSLog(@"==============================");
    NSLog(@" ");
    
    age = [obj getAge];
    NSLog(@"tiger age: %tu", age);
    NSLog(@"==============================");
    NSLog(@" ");
    
    ///////////////////////////////////////////////////////////////
    
    Animal *baseObj = [[Animal alloc] init];

    NSLog(@" ");
    NSLog(@"==============================");
    age = [baseObj getAge];
    NSLog(@"Animal age: %tu", age);
    NSLog(@"==============================");
    NSLog(@" ");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
