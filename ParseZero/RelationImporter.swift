//
//  RelationImporter.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-11-23.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Bolts
import Parse

struct RelationImporter:Importer {
  
  static func parseClassNameToRelationName(className:String) -> (relationKey:String, ownerClassName:String, targetClassName:String)
  {
    let components = className.componentsSeparatedByString(":")
    return (components[1],components[2], components.last!)
  }
  
  static func importOnKeyName(relationDefinitionString:String, _ objects:[[String : AnyObject]]) -> BFTask
  {
    let relationDefinition = parseClassNameToRelationName(relationDefinitionString)
    let relationKey = relationDefinition.relationKey
    let ownerClassName = relationDefinition.ownerClassName
    let targetClassName = relationDefinition.targetClassName
    
    return importRelations(forClassName: ownerClassName, onKey: relationKey, targetClassName: targetClassName, objects: objects)
  }
  
  static func importRelations(forClassName ownerClassName:String,onKey relationKey:String, targetClassName:String, objects:[[String : AnyObject]]) -> BFTask {
    
    print("Doing Relation \(ownerClassName).\(relationKey) -> \(targetClassName)")
    
    return objects.map({ (object) -> BFTask in
      
      
      guard
        
        let owningId = object["owningId"] as? String,
        let relatedId = object["relatedId"] as? String
        
      else{
        //          assert(false,"Invalid relation object definition\n\nRelation definition should have owningId and relatedId keys")
        return BFTask.pzero_error()
      }
      
      return PFQuery(className: ownerClassName, predicate: NSPredicate(format: "objectId == %@", owningId))
        .fromLocalDatastore()
        .ignoreACLs()
        .findObjectsInBackground()
        .continueWithBlock({ (task) -> AnyObject! in
          guard let results = task.result as? [PFObject], let sourceObject = results.first else {
            return task
          }
          
          let relation = sourceObject.relationForKey(relationKey)
          let targetObject = PFObject(withoutDataWithClassName: targetClassName, objectId: relatedId)
          relation.addObject(targetObject)
          return sourceObject.pinInBackground().continueWithBlock({ (task) -> AnyObject! in
            print("\(task.result) \(task.error) \(task.exception)")
            return task
          })
        
        })
      
    }).taskForCompletionOfAll()
  }
  
}