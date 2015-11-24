//
//  ParseZeroError.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Bolts

internal let kPZeroErrorDomain = "com.flovilmart.parsezero"

enum PZeroErrorCode:Int
{
  case UnknownError = -1
  case CannotStatDirectory = 1
  case InvalidRelationObject = 2
  case CannotLoadFile = 3
  case InvalidJSON = 4
  
  func localizedDescription() -> String
  {
    switch self {
    case .CannotStatDirectory:
      return "Cannot read content of directory"
    case .InvalidRelationObject:
      return "The relation is badly formed, should have properties owningId AND relatedId"
    case .CannotLoadFile:
      return "Cannot Load File, it may not exist"
    case .InvalidJSON:
      return "The JSON in the file is badly formed"
    default:
      return "Unknown Error"
    }
  }
}

internal extension NSError
{
  internal static func pzero_error(code:PZeroErrorCode = .UnknownError, var userInfo:[NSObject:AnyObject] = [NSObject:AnyObject]()) -> NSError
  {
    if userInfo[NSLocalizedDescriptionKey] == nil
    {
      userInfo[NSLocalizedDescriptionKey] = code.localizedDescription()
    }
    
    return NSError(domain: kPZeroErrorDomain, code: code.rawValue, userInfo: userInfo)
  }
}