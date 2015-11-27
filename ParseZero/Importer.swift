//
//  Importer.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Bolts

let kJSONPathExtension = "json"

internal protocol Importer {
  
  static func importFiles(files: [NSURL]) -> BFTask
  static func importFileAtURL(path: NSURL) -> BFTask
  static func loadFileAtURL(path: NSURL) -> ResultTuple?
  static func importAll(tuples: [ResultTuple]) -> BFTask
  static func importOnKeyName(keyName: String, _: ResultArray) -> BFTask
  
}

internal extension Importer {
  
  internal static func importFiles(files: [NSURL]) -> BFTask {
    
    return files.map {
      importFileAtURL($0)
    }.taskForCompletionOfAll()
    
  }
  
  internal static func importAll(tuples: [ResultTuple]) -> BFTask
  {
    return tuples.map {
       importOnKeyName($0.0, $0.1)
    }.taskForCompletionOfAll()
  }
  
  internal static func loadFileAtURL(path: NSURL) -> ResultTuple? {
    
    guard let lastPathComponent = path.lastPathComponent where path.pathExtension == kJSONPathExtension,
      let data = NSData(contentsOfURL: path)
      else { return nil }

    let className = (lastPathComponent as NSString).stringByDeletingPathExtension
    // Load the json
    let json: AnyObject!
    do {
      json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
    } catch { return nil }
    
    // Make sure we have the proper structure
    guard let objects = json["results"] as? ResultArray
      else { return nil }
    
    return (className, objects)
    
  }
  
  static func importFileAtURL(path: NSURL) -> BFTask {
    let relationString: String!
    let objects: [[String: AnyObject]]!
    
    guard let loadedFile = self.loadFileAtURL(path)
      else { return BFTask(result: true) }
    
    relationString = loadedFile.0
    objects = loadedFile.1
    
    return importOnKeyName(relationString, objects)
  }
  
}