//
//  BFTask+Additions.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Bolts

internal extension BFTask
{
  internal static func pzero_error(code:PZeroErrorCode, userInfo:[NSObject:AnyObject] = [NSObject:AnyObject]()) -> BFTask
  {
    return BFTask(error: NSError.pzero_error(code, userInfo: userInfo))
  }
}

internal extension Array where Element: BFTask
{
  internal func taskForCompletionOfAll() -> BFTask {
    return BFTask(forCompletionOfAllTasksWithResults: self)
  }
}