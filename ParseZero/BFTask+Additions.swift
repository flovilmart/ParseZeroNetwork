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
  
  internal static func pzero_error(code: PZeroErrorCode, userInfo: [NSObject: AnyObject] = [:]) -> BFTask {
    return BFTask(error: code.toError(userInfo))
  }
  
  internal func then(block: BFContinuationBlock) -> BFTask {
    return continueWithBlock(block)
  }
  
  internal func mergeResultsWith(task: BFTask) -> BFTask
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
    
    return self.continueWithBlock({ (task) -> AnyObject? in
      
      if let result = task.result where task.completed {
        if let result = task.result as? [AnyObject] {
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
  
  internal func taskForCompletionOfAll() -> BFTask {
    return BFTask(forCompletionOfAllTasksWithResults: self)
  }
  
}