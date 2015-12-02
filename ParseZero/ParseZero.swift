//
//  ParseZero.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Parse
import Bolts

private let kJoinPrefixString = "_Join"

typealias JSONObject = [String: AnyObject]
typealias ResultArray = [JSONObject]
typealias ResultTuple = (String, ResultArray)
typealias KeyedResultArray = [String: ResultArray]
typealias SplitResultTuples = (classes: [ResultTuple], joins: [ResultTuple])
typealias SplitNSURLTuples = (classes: [NSURL], joins: [NSURL])

/// ParseZero preloads data into the Parse local datastore
@objc(ParseZero)
public class ParseZero: NSObject {
  
  /**
   Load data from a JSON file at the specified path
   
   - parameter path: the path to find the JSON file
   
   - returns: a BFTask that completes when all data in the JSON file is imported
   - The JSON file should be in the following format:
   
   ```
   { 
    "ClassName" : [{ 
      "objectId": "id1",
      "key" : "param", ...
    }, ... ] ,
   
    "AnotherClass": [],
   
    "_Join:relationKey:OwnerClass:TargetClass" : [{
      "owningId":"id_owner", // ID of the object that owns the relation
      "relatedId": "id_related" // ID of the object in the relation
    }, ...]
   }
   ```
   
   - All objects can/should be generated from a JSON of the object with the JS/node api
   - Relations follow the same format as the Parse Export options
   - **!! You need to specify the relationships in the given format !!**
   */
  public static func loadJSONAtPath(path: String) -> BFTask {
    guard let data = NSData(contentsOfURL: NSURL(fileURLWithPath: path))
      else { return BFTask.pzero_error(.CannotLoadFile, userInfo: ["path": path]) }
    
    let JSONObject: KeyedResultArray
    
    do
    {
      JSONObject = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) as! KeyedResultArray
    } catch { return BFTask.pzero_error(.InvalidJSON, userInfo: ["path": path]) }
    
    let initial = SplitResultTuples([], [])
    
    let result = JSONObject.reduce(initial) { (var memo, value) -> SplitResultTuples in
      
      // We have a _Join prefix
      if value.0.hasPrefix(kJoinPrefixString) {
        memo.joins.append(value)
      } else {
        memo.classes.append(value)
      }
      return memo
    }
    
    return ClassImporter.importAll(result.classes).then({ (task) -> AnyObject! in
      return RelationImporter.importAll(result.joins).mergeResultsWith(task)
    })
  }
  
  /**
   Load data from a all the .json files found in the directory at the sepecified path
   
   - parameter path: a path to a directory holding all the data
   
   - returns: a BFTask that completes when all data in the JSON files is imported
   
   - Relation file names should follow the following format:
   
   **_Join:relationKey:OwnerClass:TargetClass.json**
   
   (it differs from Parse's export as the TargetClass should be specified)
   */
  public static func loadDirectoryAtPath(path: String) -> BFTask {
    
    let contents:[String]
    do {
      contents = try NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)
    } catch {
      return BFTask.pzero_error(.CannotStatDirectory, userInfo: ["path":path])
    }
    
    
    let files = contents.map { (filePath) -> NSURL in
      NSURL(fileURLWithPath: path).URLByAppendingPathComponent(filePath)
    }
    
    return loadFiles(files)
  }
  
  /**
   Loads the data from a set of file with their full URL's
   
   - parameter files: the list of JSON files that hold the data to import
   
   - returns: a BFTask that completes when all data in the JSON files is imported
   */
  public static func loadFiles(files: [NSURL]) -> BFTask {
    
    let initial = SplitNSURLTuples([],[])
    
    let urls = files.reduce(initial) { (var memo, url) -> SplitNSURLTuples in
      
      if url.lastPathComponent!.hasPrefix(kJoinPrefixString)
      {
        memo.joins.append(url)
      } else {
        memo.classes.append(url)
      }
      return memo
    }

    return ClassImporter.importFiles(urls.classes).then({ (task) -> AnyObject! in
      return RelationImporter.importFiles(urls.joins).mergeResultsWith(task)
    })
  }
  
}