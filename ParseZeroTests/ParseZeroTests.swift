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
      ParseZero.trace = true;
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
      
  func testLoadInvalidFile() {
    XCTAssertNil(ClassImporter.loadFileAtURL(NSURL(fileURLWithPath:"/some/file")))
  }
  
  func testLoadInvalidDirectory() {
    XCTAssertNotNil(ParseZero.loadDirectoryAtPath("/some/file").error)
  }
  func testLoadInvalidJSON() {
    XCTAssertNotNil(ParseZero.loadJSONAtPath("/some/file").error)
  }
  
  func testLoadMalformedJSON() {
    let jsonPath = NSBundle(forClass: ParseZeroTests.self).pathForResource("Malformed", ofType: "json")!
    let jsonURL = NSURL(fileURLWithPath: jsonPath)
    XCTAssertNotNil(ParseZero.loadJSONAtPath(jsonPath))
    
    XCTAssertNil(ClassImporter.loadFileAtURL(jsonURL))
    XCTAssertNotNil(ClassImporter.importFileAtURL(jsonURL).result, "Should return a task with result")
  }
  
  func testNoResultInJSON() {
    let jsonPath = NSBundle(forClass: ParseZeroTests.self).pathForResource("AllObjects", ofType: "json")!
    let jsonURL = NSURL(fileURLWithPath: jsonPath)
    XCTAssertNil(ClassImporter.loadFileAtURL(jsonURL))
  }
  
  func testMissingObjectIdKey() {
    let expecation = self.expectationWithDescription("wait")
    ClassImporter.importOnKeyName("AClass", [["some": "thing"]]).continueWithBlock { (task) -> AnyObject? in
      XCTAssertNotNil(task.error)
      expecation.fulfill()
      return task
    }
    self.waitForExpectationsWithTimeout(10, handler: nil)
  }
  
  func testInvalidRelationKeys() {
    let relation = (key:"a", ownerClassName:"AClass", targetClassName:"OtherClass")
    XCTAssertNotNil(RelationImporter.importRelations(relation, objects: [["key":"value", "otherKey": "OtherVlaue"]]).error)
  }
  
  func testRelationNotFoundObject() {
    let expectation = self.expectationWithDescription("wait")
    let relation = (key:"a", ownerClassName:"AClass", targetClassName:"OtherClass")
    
    RelationImporter.importRelations(relation, objects: [["owningId":"value", "relatedId": "OtherVlaue"]]).continueWithBlock { (task) -> AnyObject! in
      XCTAssertNotNil(task.result)
      expectation.fulfill()
      return task
    }
    waitForExpectationsWithTimeout(10.0, handler: nil)
    
  }
  
  func testBFTasks() {
    BFTask(result: nil).continueWithBlock{ (task) -> AnyObject? in
      return BFTask(result: ["key":"value"]).mergeResultsWith(task)
    }.continueWithBlock { (task) -> AnyObject? in
      return BFTask(result: ["Some", "Strings"]).mergeResultsWith(task)
    }.continueWithBlock { (task) -> AnyObject? in
      return BFTask(result: "hello").mergeResultsWith(task)
    }.continueWithBlock { (task) -> AnyObject? in
      return BFTask(result: nil).mergeResultsWith(task)
    }.continueWithBlock { (task) -> AnyObject? in
      let result = task.result as! [AnyObject]
      XCTAssertEqual(result.count, 4)
      return BFTask(result: "hello")
    }.continueWithBlock{ (task) -> AnyObject? in
        return BFTask(result: ["key":"value"]).mergeResultsWith(task)
    }.continueWithBlock { (task) -> AnyObject? in
        return BFTask(result: ["Some", "Strings"]).mergeResultsWith(task)
    }.continueWithBlock { (task) -> AnyObject? in
      let result = task.result as! [AnyObject]
      XCTAssertEqual(result.count, 4)
      return task
    }
  }

}
