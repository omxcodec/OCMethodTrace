//
//  ViewController.m
//  OCMethodTraceDemo
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import "ViewController.h"
#import "Tiger.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // insert code here...
    [self testMain];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)testMain {
    [self test1];
    [self test2];
}
    
- (void)test1 {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // insert code here...
    NSLog(@"Hello, OCMethodTrace!");
    
    NSLog(@" ");
    NSLog(@"==============================");
    NSLog(@"Tiger setLogLevel:");
    [Tiger setLogLevel:1];
    NSLog(@"==============================");
    NSLog(@" ");
    
    Tiger *obj = [[Tiger alloc] init];
    
    NSString *name = nil;
    NSUInteger age = 0;
    
    ///////////////////////////////////////////////////////////////
    
    NSLog(@" ");
    NSLog(@"==============================");
    NSLog(@"Tiger setName:age:");
    [obj setName:@"Tiger-0" age:5];
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    name = [obj getName];
    NSLog(@"Tiger name: %@", name);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    age = [obj getAge];
    NSLog(@"Tiger age: %tu", age);
    NSLog(@"==============================");
    NSLog(@" ");
    
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct1 st1 = [obj setObjStruct1:'a'];
    NSLog(@"Tiger setObjStruct1: a: %c", st1.a);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct4 st4 = [obj setObjStruct4:1];
    NSLog(@"Tiger setObjStruct4: a: %d", st4.a);
    NSLog(@"==============================");
    NSLog(@" ");
    
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct8 st8 = [obj setObjStruct8:1];
    NSLog(@"Tiger setObjStruct8: a: %lld", st8.a);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct16 st16 = [obj setObjStruct16:1 b:2];
    NSLog(@"Tiger setObjStruct16: a: %lld b: %lld", st16.a, st16.b);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct24 st24 = [obj setObjStruct24:1 b:2 c:3];
    NSLog(@"Tiger setObjStruct24: a: %lld b: %lld b: %lld", st24.a, st24.b, st24.c);
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    ObjStruct32 st32 = [obj setObjStruct32:1 b:2 c:3 d:4];
    NSLog(@"Tiger setObjStruct32: a: %lld b: %lld c: %lld d: %lld", st32.a, st32.b, st32.c, st32.d);
    NSLog(@"==============================");
    NSLog(@" ");
    
    ///////////////////////////////////////////////////////////////
    
    NSLog(@" ");
    NSLog(@"==============================");
    NSLog(@"Tiger setName:");
    [obj setName:@"Tiger-1"];
    NSLog(@"==============================");
    NSLog(@" ");
    
    NSLog(@" ");
    NSLog(@"==============================");
    name = [obj getName];
    NSLog(@"Tiger name: %@", name);
    NSLog(@"==============================");
    NSLog(@" ");
    
    ///////////////////////////////////////////////////////////////
    
    NSLog(@" ");
    NSLog(@"==============================");
    NSLog(@"Tiger setAge:");
    [obj setAge:10];
    NSLog(@"==============================");
    NSLog(@" ");
    
    age = [obj getAge];
    NSLog(@"Tiger age: %tu", age);
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

- (void)test2 {
    dispatch_queue_t concurrentQueue = dispatch_queue_create("com.summer.concurrent", DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(concurrentQueue, ^{
        int level = 0;
        do {
            [Animal setLogLevel:level++];
            Animal *baseObj = [[Animal alloc] init];
            [baseObj setName:@"123"];
            sleep(1);
        } while(1);
    });
}

@end
