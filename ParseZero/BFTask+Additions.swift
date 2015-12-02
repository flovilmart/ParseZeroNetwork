//
//  BFTask+Additions.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Bolts

internal extension BFTask {
  
  static func pzero_error(code: PZeroErrorCode, userInfo: [NSObject: AnyObject] = [:]) -> BFTask {
    return BFTask(error: code.toError(userInfo))
  }
  
  func then(block: BFContinuationBlock) -> BFTask {
    return continueWithSuccessBlock(block)
  }
  
  func mergeResultsWith(task: BFTask) -> BFTask
  {
    var results: [AnyObject]
    if let result = task.result {
      if let result = result as? [AnyObject] {
        results = result
      } else {
        results = [result]
      }
    } else {
      results = [AnyObject]()
    }
    
    return self.continueWithBlock({ (otherTask) -> AnyObject! in
      
      if let result:AnyObject = otherTask.result where otherTask.completed {
        if let result = otherTask.result as? [AnyObject] {
          results.appendContentsOf(result)
        } else {
          results.append(result)
        }
      }
      return BFTask(result: results)
    })
  }
  
}

internal extension Array where Element: BFTask {
  
  func taskForCompletionOfAll() -> BFTask {
    return BFTask(forCompletionOfAllTasksWithResults: self)
  }
  
}