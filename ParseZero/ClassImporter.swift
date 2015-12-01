//
//  ClassImporter.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Bolts
import Parse

internal struct ClassImporter: Importer {
  
  static func importOnKeyName(className: String, _ objects: ResultArray) -> BFTask {
    // Create a task that waits for all to complete
    return objects.map { (objectJSON) -> BFTask in
      
      guard let objectId = objectJSON["objectId"] as? String else {
        return BFTask.pzero_error(.MissingObjectIdKey)
      }
      
      return PFQuery(className: className, predicate: NSPredicate(format: "objectId == %@", objectId))
        .fromLocalDatastore()
        .ignoreACLs()
        .findObjectsInBackground()
        .continueWithBlock({ (task) -> AnyObject! in
          
          if let objects = task.result as? [PFObject] where objects.count == 0 || task.result == nil || task.error != nil {
            return self.pinObject(className, objectId: objectId, objectJSON: objectJSON)
          }
          
          return BFTask(result: "Not updating \(className) \(objectId)")
          
        })
    
    }.taskForCompletionOfAll()
  }
  
  
  private static func pinObject(className: String, objectId: String, objectJSON: JSONObject) -> BFTask {
    
    let parseObject = PFObject.mockedServerObject(className, objectId: objectId, data: objectJSON)
    
    return parseObject.pinInBackground().continueWithSuccessBlock({ (task) -> AnyObject! in
      return BFTask(result: "Saved \(className) \(objectId)")
    })
  }

}