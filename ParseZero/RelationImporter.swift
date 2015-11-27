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

typealias PFObjectsMap = [String:[PFObject]]
typealias RelationDefinition = (key:String, ownerClassName:String, targetClassName:String)


struct RelationImporter:Importer {
  
  static func parseClassNameToRelation(className:String) -> RelationDefinition {
    let components = className.componentsSeparatedByString(":")
    return (components[1],components[2], components.last!)
  }
  
  static func importOnKeyName(relationDefinitionString:String, _ objects:ResultArray) -> BFTask {
    
    let relation = parseClassNameToRelation(relationDefinitionString)
    
    return importRelations(relation, objects: objects)
  }
  
  static func validateObjects(objects: ResultArray) -> BFTask? {

    let errors = objects.reduce([BFTask]()) { (var memo, object) -> [BFTask] in
      if let _ = object["owningId"] as? String,
        let _ = object["relatedId"] as? String {
          // do nothing
      } else {
          memo.append(BFTask.pzero_error(.InvalidRelationObject, userInfo: ["object": object]))
      }
      return memo
    }
    
    if errors.count > 0 {
      return BFTask(forCompletionOfAllTasksWithResults: errors)
    }
    
    return nil
  }
  
  static func importRelations(relationDefinition: RelationDefinition, objects:ResultArray) -> BFTask {
    
    let ownerClassName = relationDefinition.ownerClassName
    let targetClassName = relationDefinition.targetClassName
    let ownerKey = relationDefinition.key
        
    if let error = self.validateObjects(objects) {
      return error
    }
    
    return objects.reduce(PFObjectsMap()) { (var memo, object) -> PFObjectsMap in
      
      // we can force unpack here as it's validated
      let owningId = object["owningId"] as! String
      let relatedId = object["relatedId"] as! String
      
      if memo[owningId] == nil {
        memo[owningId] = [PFObject]()
      }
      
      let parseObject = PFObject(withoutDataWithClassName: targetClassName, objectId: relatedId)
      
      memo[owningId]!.append(parseObject)
      
      return memo
      
    }.map { (relations) -> BFTask in
      
      let owningId = relations.0
      
      // Fetch the owning id
      return PFQuery(className: ownerClassName, predicate: NSPredicate(format: "objectId == %@", owningId))
        .fromLocalDatastore()
        .ignoreACLs()
        .findObjectsInBackground()
        .continueWithBlock({ (task) -> AnyObject! in
          guard let results = task.result as? [PFObject], let sourceObject = results.first else {
            return task
          }
          
          let relatedObjects = relations.1
          for object in relatedObjects {
            sourceObject.relationForKey(ownerKey).addObject(object)
          }
          
          return sourceObject.pinInBackground().continueWithBlock({ (task) -> AnyObject! in
            if task.completed {
              let ids = relatedObjects.map({ (object) -> String in
                return object.objectId!
              })
              return BFTask(result: "Saved Relations from:\(ownerClassName) \(sourceObject.objectId)\nto \(targetClassName) - \(ids)")
            }
            return task
          })
        })
      
    }.taskForCompletionOfAll()
  }
  
}