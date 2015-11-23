//
//  ParseZeroError.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Bolts

internal extension NSError
{
  internal static func pzero_error() -> NSError
  {
    return NSError(domain: "", code: 0, userInfo: nil)
  }
}