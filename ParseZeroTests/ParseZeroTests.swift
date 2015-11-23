//
//  ParseZeroTests.swift
//  ParseZeroTests
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import XCTest
import Parse
import Bolts
@testable import ParseZero



@objc
class ParseZeroTests: XCTestCase {

    override func setUp() {
      super.setUp()
      ParseZeroObjC.initializeParse()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
      PFQuery.clearAllCachedResults()
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
      let expectation = self.expectationWithDescription("Wait for it...")
      
      ParseZero.loadDirectoryAtPath(NSBundle(forClass: ParseZeroTests.self).bundlePath+"/ParseObjects").continueWithBlock { (task) -> AnyObject! in
        XCTAssert(task.error == nil)
        XCTAssert(task.exception == nil)
        expectation.fulfill()
        return nil
      }
      
      waitForExpectationsWithTimeout(3000.0, handler: nil)
    }
    
}
