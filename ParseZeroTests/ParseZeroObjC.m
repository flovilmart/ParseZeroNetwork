//
//  ParseZeroObjC.m
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

#import "ParseZeroTests-Bridging-Header.h"
@import Parse;
@import Bolts;
@import ParseZero;

@implementation ParseZeroObjC

+ (void)initializeParse
{
  if (![Parse isLocalDatastoreEnabled]) {
    NSString *library = [NSHomeDirectory() stringByAppendingPathComponent:@"Library"];
    NSString *privateDocuments = [library stringByAppendingPathComponent:@"Private Documents"];
    NSString *directoryPath = [privateDocuments stringByAppendingPathComponent:@"Parse"];
    [[NSFileManager defaultManager] removeItemAtPath:directoryPath error:nil];
    NSLog(@"%@", directoryPath);
    [Parse enableLocalDatastore];
    [Parse setApplicationId:@"AAAAAAAAAAAA" clientKey:@"AAAAAAAAAAAA"];
  }
}

- (void)setUp {
    [super setUp];
    [ParseZeroObjC initializeParse];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFromFile {
  
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
  XCTestExpectation *expectation  = [self expectationWithDescription:@"Wait for it"];
  NSString *objectsFile = [[NSBundle bundleForClass:[ParseZeroObjC class]] pathForResource:@"AllObjects" ofType:@"json"];
  
  [[ParseZero loadJSONAtPath:objectsFile] continueWithBlock:^id(BFTask *task) {
    XCTAssert(task.error == nil);
    XCTAssert(task.exception == nil);
    
    [self checkIntegrity];
    
    [expectation fulfill];
    return nil;
  }];
  
  [self waitForExpectationsWithTimeout:3000 handler:nil];
}

- (void)testFromFolder {
  
  // This is an example of a functional test case.
  // Use XCTAssert and related functions to verify your tests produce the correct results.
  XCTestExpectation *expectation  = [self expectationWithDescription:@"Wait for it"];
  NSString *objectsDirectory = [[NSBundle bundleForClass:[ParseZeroObjC class]].bundlePath stringByAppendingString:@"/ParseObjects"];
  
  [[ParseZero loadDirectoryAtPath:objectsDirectory] continueWithBlock:^id(BFTask *task) {
    XCTAssert(task.error == nil);
    XCTAssert(task.exception == nil);
    [self checkIntegrity];
     [expectation fulfill];
  }];
  
  [self waitForExpectationsWithTimeout:3000 handler:nil];
}

- (void)checkIntegrity
{
  // Make sure we imported enought objects
  NSInteger aCount = [[[PFQuery queryWithClassName:@"ClassA"] fromPin] countObjects];
  XCTAssertEqual(aCount, 3);
  
  // Make sure we imported enought objects
  NSInteger bCount = [[[PFQuery queryWithClassName:@"ClassB"] fromPin] countObjects];
  XCTAssertEqual(bCount, 3);
  

  // Test if the relation is properly set
  NSArray *objects = [[[[[[[PFObject objectWithoutDataWithClassName:@"ClassA" objectId:@"2"] fetchFromLocalDatastore] relationForKey:@"bs"] query] fromPin] ignoreACLs] findObjects];
  
  XCTAssertEqual([objects count], 1);
  
    // Test if the relations are properly set
  NSError *error;
 objects = [[[[[[[PFObject objectWithoutDataWithClassName:@"ClassA" objectId:@"1"] fetchFromLocalDatastore] relationForKey:@"bs"] query] fromPin] ignoreACLs] findObjects:&error];
  XCTAssertEqual([objects count], 3);
  XCTAssertNil(error);

  objects = [[[[[[[PFObject objectWithoutDataWithClassName:@"ClassA" objectId:@"1"] fetchFromLocalDatastore] relationForKey:@"bs"] query] fromLocalDatastore] ignoreACLs] findObjects];
  XCTAssertEqual([objects count], 3);
  
  // Fetch A1 to test if the Pointer is properly set
  PFObject *a1 = [[PFObject objectWithoutDataWithClassName:@"ClassA" objectId:@"1"]fetchFromLocalDatastore];
  NSString *bName = [a1[@"b"] fetchFromLocalDatastore][@"name"];
  XCTAssert([bName isEqualToString:@"Object4"], @"bname should be set to Object4");
  
}

@end
