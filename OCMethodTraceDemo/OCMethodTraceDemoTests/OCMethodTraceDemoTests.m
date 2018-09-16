//
//  OCMethodTraceDemoTests.m
//  OCMethodTraceDemoTests
//
//  Created by Michael Chen on 2018/9/9.
//  Copyright (C) 2018 Michael Chen <omxcodec@gmail.com>
//

#import <XCTest/XCTest.h>
#import "OCMethodTrace.h"
#import "TestUtils.h"

// Copy from ANYMethodLogDemoTests.m
// https://github.com/qhd/ANYMethodLog.git

#pragma mark - 测试类TestObject

@interface TestObject : NSObject

//- (void)initSupportedTypeDic
//{
//    self.supportedTypeDic = @{[NSString stringWithUTF8String:@encode(char)] : @"(char)",
//                              [NSString stringWithUTF8String:@encode(int)] : @"(int)",
//                              [NSString stringWithUTF8String:@encode(short)] : @"(short)",
//                              [NSString stringWithUTF8String:@encode(long)] : @"(long)",
//                              [NSString stringWithUTF8String:@encode(long long)] : @"(long long)",
//                              [NSString stringWithUTF8String:@encode(unsigned char)] : @"(unsigned char))",
//                              [NSString stringWithUTF8String:@encode(unsigned int)] : @"(unsigned int)",
//                              [NSString stringWithUTF8String:@encode(unsigned short)] : @"(unsigned short)",
//                              [NSString stringWithUTF8String:@encode(unsigned long)] : @"(unsigned long)",
//                              [NSString stringWithUTF8String:@encode(unsigned long long)] : @"(unsigned long long)",
//                              [NSString stringWithUTF8String:@encode(float)] : @"(float)",
//                              [NSString stringWithUTF8String:@encode(double)] : @"(double)",
//                              [NSString stringWithUTF8String:@encode(BOOL)] : @"(BOOL)",
//                              [NSString stringWithUTF8String:@encode(void)] : @"(void)",
//                              [NSString stringWithUTF8String:@encode(char *)] : @"(char *)",
//                              [NSString stringWithUTF8String:@encode(id)] : @"(id)",
//                              [NSString stringWithUTF8String:@encode(Class)] : @"(Class)",
//                              [NSString stringWithUTF8String:@encode(SEL)] : @"(SEL)",
//                              [NSString stringWithUTF8String:@encode(CGRect)] : @"(CGRect)",
//                              [NSString stringWithUTF8String:@encode(CGPoint)] : @"(CGPoint)",
//                              [NSString stringWithUTF8String:@encode(CGSize)] : @"(CGSize)",
//                              [NSString stringWithUTF8String:@encode(CGVector)] : @"(CGVector)",
//                              [NSString stringWithUTF8String:@encode(CGAffineTransform)] : @"(CGAffineTransform)",
//                              [NSString stringWithUTF8String:@encode(UIOffset)] : @"(UIOffset)",
//                              [NSString stringWithUTF8String:@encode(UIEdgeInsets)] : @"(UIEdgeInsets)",
//                              @"@?":@"(block)", // block类型
//                              }; // 添加更多类型
//}

- (BOOL)methodWithA:(char)a
                  b:(int)b
                  c:(short)c
                  d:(long)d
                  e:(long long)e
                  f:(unsigned char)f
                  g:(unsigned int)g
                  h:(unsigned short)h
                  i:(unsigned long)i
                  j:(unsigned long long)j
                  k:(float)k
                  l:(double)l
                  m:(bool)m
                  //n:(void)n
                  o:(char *)o
                  p:(id)p
                  q:(Class)q
                  r:(SEL)r
                  s:(CGRect)s
                  t:(CGPoint)t
                  u:(CGSize)u
                  v:(CGVector)v
                  w:(CGAffineTransform)w
                  x:(UIOffset)x
                  y:(UIEdgeInsets)y;
- (char)method1:(char)a;
- (int)method2:(int)a;
- (short)method3:(short)a;
- (long)method4:(long)a;
- (long long)method5:(long long)a;
- (unsigned char)method6:(unsigned char)a;
- (unsigned int)method7:(unsigned int)a;
- (unsigned short)method8:(unsigned short)a;
- (unsigned long)method9:(unsigned long)a;
- (unsigned long long)method10:(unsigned long long)a;
- (float)method11:(float)a ;
- (double)method12:(double)a;
- (BOOL)method13:(BOOL)a;
- (void)method14;
- (char *)method15:(char *)a;
- (id)method16:(id)a;
- (Class)method17:(Class)a;
- (SEL)method18:(SEL)a;
- (CGRect)method19:(CGRect)a;
- (CGPoint)method20:(CGPoint)a;
- (CGSize)method21:(CGSize)a;
- (CGVector)method22:(CGVector)a;
- (CGAffineTransform)method23:(CGAffineTransform)a;
- (UIEdgeInsets)method24:(UIEdgeInsets)a;
- (UIOffset)method25:(UIOffset)a;
- (void (^)())method26:(void (^)())a;
- (ObjStruct1)method27:(ObjStruct1)a;
- (ObjStruct4)method28:(ObjStruct4)a;
- (ObjStruct8)method29:(ObjStruct8)a;
- (ObjStruct16)method30:(ObjStruct16)a;
- (ObjStruct24)method31:(ObjStruct24)a;
- (ObjStruct32)method32:(ObjStruct32)a;

@end

@implementation TestObject

- (BOOL)methodWithA:(char)a
                  b:(int)b
                  c:(short)c
                  d:(long)d
                  e:(long long)e
                  f:(unsigned char)f
                  g:(unsigned int)g
                  h:(unsigned short)h
                  i:(unsigned long)i
                  j:(unsigned long long)j
                  k:(float)k
                  l:(double)l
                  m:(bool)m
//n:(void)n
                  o:(char *)o
                  p:(id)p
                  q:(Class)q
                  r:(SEL)r
                  s:(CGRect)s
                  t:(CGPoint)t
                  u:(CGSize)u
                  v:(CGVector)v
                  w:(CGAffineTransform)w
                  x:(UIOffset)x
                  y:(UIEdgeInsets)y
{
    TestLog(@"a: %@, b: %@, c: %@, d: %@, e: %@, f: %@, g: %@, h: %@, i: %@, j: %@, k: %@, l: %@, m: %@, n: void,o: %@, p: %@, q: %@, r: %@, s:%@, t:%@, u: %@, v: %@, w: %@, x: %@, y: %@",
            [@(a) stringValue],
            [@(b) stringValue],
            [@(c) stringValue],
            [@(d) stringValue],
            [@(e) stringValue],
            [@(f) stringValue],
            [@(g) stringValue],
            [@(h) stringValue],
            [@(i) stringValue],
            [@(j) stringValue],
            [@(k) stringValue],
            [@(l) stringValue],
            [@(m) stringValue],
            [NSString stringWithUTF8String:o],
            p,
            NSStringFromClass(q),
            NSStringFromSelector(r),
            NSStringFromCGRect(s),
            NSStringFromCGPoint(t),
            NSStringFromCGSize(u),
            NSStringFromCGVector(v),
            NSStringFromCGAffineTransform(w),
            NSStringFromUIOffset(x),
            NSStringFromUIEdgeInsets(y)
          );
    return YES;
}

- (char)method1:(char)a {
    TestLog();
    return a;
}

- (int)method2:(int)a {
    TestLog();
    return a;
}

- (short)method3:(short)a {
    TestLog();
    return a;
}

- (long)method4:(long)a {
    TestLog();
    return a;
}

- (long long)method5:(long long)a {
    TestLog();
    return a;
}

- (unsigned char)method6:(unsigned char)a {
    TestLog();
    return a;
}

- (unsigned int)method7:(unsigned int)a {
    TestLog();
    return a;
}

- (unsigned short)method8:(unsigned short)a {
    TestLog();
    return a;
}

- (unsigned long)method9:(unsigned long)a {
    TestLog();
    return a;
}

- (unsigned long long)method10:(unsigned long long)a {
    TestLog();
    return a;
}

- (float)method11:(float)a  {
    TestLog();
    return a;
}

- (double)method12:(double)a {
    TestLog();
    return a;
}

- (BOOL)method13:(BOOL)a {
    TestLog();
    return a;
}

- (void)method14 {
    TestLog();
}

- (char *)method15:(char *)a {
    TestLog();
    return a;
}

- (id)method16:(id)a {
    TestLog();
    return a;
}

- (Class)method17:(Class)a {
    TestLog();
    return a;
}

- (SEL)method18:(SEL)a {
    TestLog();
    return a;
}

- (CGRect)method19:(CGRect)a {
    TestLog();
    return a;
}

- (CGPoint)method20:(CGPoint)a {
    TestLog();
    return a;
}

- (CGSize)method21:(CGSize)a {
    TestLog();
    return a;
}

- (CGVector)method22:(CGVector)a {
    TestLog();
    return a;
}

- (CGAffineTransform)method23:(CGAffineTransform)a {
    TestLog();
    return a;
}

- (UIEdgeInsets)method24:(UIEdgeInsets)a {
    TestLog();
    return a;
}

- (UIOffset)method25:(UIOffset)a {
    TestLog();
    return a;
}

- (void (^)())method26:(void (^)())a {
    TestLog();
    return a;
}

- (ObjStruct1)method27:(ObjStruct1)a {
    TestLog();
    return a;
}
- (ObjStruct4)method28:(ObjStruct4)a {
    TestLog();
    return a;
}

- (ObjStruct8)method29:(ObjStruct8)a {
    TestLog();
    return a;
}

- (ObjStruct16)method30:(ObjStruct16)a {
    TestLog();
    return a;
}

- (ObjStruct24)method31:(ObjStruct24)a {
    TestLog();
    return a;
}

- (ObjStruct32)method32:(ObjStruct32)a {
    TestLog();
    return a;
}

@end

////////////////////////////////////////////////////////////////////////////////

@interface OCMethodTraceDemoTests : XCTestCase

@end

@implementation OCMethodTraceDemoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

- (void)testMyTestObject {
    [[OCMethodTrace getInstance] traceMethodWithClass:[TestObject class] condition:^BOOL(SEL sel) {
        return YES;
    } before:^(id target, Class cls, SEL sel, NSArray *args, NSInteger deep) {
        NSLog(@" ");
        NSLog(@"==============================");
        NSLog(@"target :%@ sel: %@ args: %@", target, NSStringFromSelector(sel), args);
    } after:^(id target, Class cls, SEL sel, NSArray *args, NSTimeInterval interval, NSInteger deep, id retValue) {
        NSLog(@"target: %@ sel: %@ retValue: %@", target, NSStringFromSelector(sel), retValue);
        NSLog(@"==============================");
        NSLog(@" ");
    }];
    
    TestObject *o = [[TestObject alloc] init];
    
    XCTAssertTrue([o methodWithA:'a'
                               b:1
                               c:12
                               d:123
                               e:1234
                               f:'u'
                               g:3
                               h:4
                               i:5
                               j:6
                               k:7.1
                               l:7.12345
                               m:YES
                               o:"hello"
                               p:o
                               q:[o class]
                               r:NSSelectorFromString(@"viewDidLoad")
                               s:CGRectMake(1.1, 1.2, 1.3, 1.4)
                               t:CGPointMake(2.11, 2.12)
                               u:CGSizeMake(3.123, 3.1234)
                               v:CGVectorMake(4.456, 4.567)
                               w:CGAffineTransformMake(6.123, 6.124, 6.125, 6.126, 6.127, 6.128)
                               x:UIOffsetMake(7.123456, 7.1234567)
                               y:UIEdgeInsetsMake(8.0, 8.0001, 8.0002, 8.0003)]);
    
    XCTAssertTrue('a' == [o method1:'a']);
    XCTAssertTrue(12 == [o method2:12]);
    XCTAssertTrue(13 == [o method3:13]);
    XCTAssertTrue(1444444 == [o method4:1444444]);
    
    long long ll = 155;
    long long llr = [o method5:ll];
    XCTAssertTrue(ll == llr);
    
    XCTAssertTrue('u' == [o method6:'u']);
    XCTAssertTrue(17 == [o method7:17]);
    XCTAssertTrue(18 == [o method8:18]);
    XCTAssertTrue(19000 == [o method9:19000]);
    XCTAssertTrue(20 == [o method10:20]);
    XCTAssertTrue(21 == [o method11:21]);
    XCTAssertTrue(22.345678 == [o method12:22.345678]);
    XCTAssertTrue(YES == [o method13:YES]);
    XCTAssertTrue(NO == [o method13:NO]);
    [o method14];
    XCTAssertTrue("c255555" == [o method15:"c255555"]);
    XCTAssertTrue(o == [o method16:o]);
    XCTAssertTrue(NSClassFromString(@"TestObject") == [o method17:NSClassFromString(@"TestObject")]);
    XCTAssertTrue(NSSelectorFromString(@"method17:") == [o method18:NSSelectorFromString(@"method17:")]);
    XCTAssertTrue(CGRectEqualToRect(CGRectMake(1.2, 1.23, 1.234, 1.2345), [o method19:CGRectMake(1.2, 1.23, 1.234, 1.2345)]));
    
    XCTAssertTrue(CGPointEqualToPoint(CGPointMake(2.3, 2.34), [o method20:CGPointMake(2.3, 2.34)]));
    XCTAssertTrue(CGSizeEqualToSize(CGSizeMake(3.4, 3.45), [o method21:CGSizeMake(3.4, 3.45)]));
    
    CGVector vector = CGVectorMake(9.234, 9.2345);
    XCTAssertTrue(vector.dx == [o method22:vector].dx && vector.dy == [o method22:vector].dy);
    
    XCTAssertTrue(CGAffineTransformEqualToTransform(CGAffineTransformMake(4.1, 4.12, 4.123, 4.1234, 4.12345, 4.123456),[o method23:CGAffineTransformMake(4.1, 4.12, 4.123, 4.1234, 4.12345, 4.123456)]));
    
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsMake(5.1, 5.12, 5.123, 5.1234), [o method24:UIEdgeInsetsMake(5.1, 5.12, 5.123, 5.1234)]));
    
    XCTAssertTrue(UIOffsetEqualToOffset(UIOffsetMake(6.123, 6.1234),[o method25:UIOffsetMake(6.123, 6.1234)]));
    
    void (^aBlock)() = ^() {
        
    };
    XCTAssertTrue(aBlock == [o method26:aBlock]);
    
    ObjStruct1 st1_1 = { 'a' };
    ObjStruct1 st1_2 = [o method27:st1_1];
    XCTAssertTrue(0 == memcmp(&st1_1, &st1_2, sizeof(st1_1)));
    
    ObjStruct4 st4_1 = { 1 };
    ObjStruct4 st4_2 = [o method28:st4_1];
    XCTAssertTrue(0 == memcmp(&st4_1, &st4_2, sizeof(st4_1)));
    
    ObjStruct8 st8_1 = { 1 };
    ObjStruct8 st8_2 = [o method29:st8_1];
    XCTAssertTrue(0 == memcmp(&st8_1, &st8_2, sizeof(st8_1)));
    
    ObjStruct16 st16_1 = { 1, 2 };
    ObjStruct16 st16_2 = [o method30:st16_1];
    XCTAssertTrue(0 == memcmp(&st16_1, &st16_2, sizeof(st16_1)));
    
    ObjStruct24 st24_1 = { 1, 2, 3 };
    ObjStruct24 st24_2 = [o method31:st24_1];
    XCTAssertTrue(0 == memcmp(&st24_1, &st24_2, sizeof(st24_1)));
    
    ObjStruct32 st32_1 = { 1, 2, 3, 4 };
    ObjStruct32 st32_2 = [o method32:st32_1];
    XCTAssertTrue(0 == memcmp(&st32_1, &st32_2, sizeof(st32_1)));
}

@end
