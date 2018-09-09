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
