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

internal struct ClassImporter:Importer {
  
  internal static func importOnKeyName(className:String, _ objects:[[String : AnyObject]]) -> BFTask
  {
    // Create a task that waits for all to complete
    return objects.map { (objectJSON) -> BFTask in
      
      let objectId = objectJSON["objectId"] as? String
      
      print("Doing \(className) \(objectId)")
      
      return PFQuery(className: className, predicate: NSPredicate(format: "objectId == %@", objectId!))
        .fromLocalDatastore()
        .ignoreACLs()
        .getFirstObjectInBackground()
        .continueWithBlock({ (task) -> AnyObject! in
          if task.result == nil || task.error != nil {
            return self.pinObject(className, objectJSON: objectJSON)
          }
          return BFTask(result: true)
        })
    
    }.taskForCompletionOfAll()
  }
  
  
  private static func pinObject(className:String, objectJSON:[String:AnyObject]) -> BFTask
  {
   
    let objectId = objectJSON["objectId"] as? String
    print("Pinning \(className) \(objectId)")
    
    let parseObject = PFObject(className: className, dictionary: objectJSON )
    parseObject.objectId = objectId
    
    return parseObject.pinInBackground()
  }

}