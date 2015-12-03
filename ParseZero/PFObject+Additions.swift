//
//  PFObject+Additions.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-12-01.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Parse

extension PFACL {
  convenience init(dictionary:JSONObject) {
    self.init()
    for (k,v) in dictionary {
      let setReadAccess = v["read"] as? Bool == true
      let setWriteAccess = v["write"] as? Bool == true
      
      if k == "*" {
        self.publicReadAccess = setReadAccess
        self.publicWriteAccess = setWriteAccess
      } else if let _ = k.rangeOfString("role:") {
        let roleName = k.stringByReplacingOccurrencesOfString("role:", withString: "")
        self.setReadAccess(setReadAccess, forRoleWithName: roleName)
        self.setWriteAccess(setWriteAccess, forRoleWithName: roleName)
      } else {
        self.setReadAccess(setReadAccess, forUserId: k)
        self.setWriteAccess(setWriteAccess, forUserId: k)
      }
    }
  }
}

extension PFObject {
  static func mockedServerObject(className: String, objectId:String,data:JSONObject) -> PFObject {
    
    var dictionary = data;
    // Remove objectId
    dictionary["objectId"] = nil
    let parseObject = PFObject(className: className)
    for kv in dictionary {
      
      var value = kv.1
      
      if let pointer = value as? JSONObject where pointer["__type"] as? String == "Pointer",
        let pointerClassName = pointer["className"] as? String,
        let pointerObjectId = pointer["objectId"] as? String {
          do {
            try value = PFQuery(className: pointerClassName).fromLocalDatastore()
              .getObjectWithId(pointerObjectId)
          } catch {
            value = PFObject(withoutDataWithClassName: pointerClassName, objectId: pointerObjectId)
          }
      } else if let acl = value as? JSONObject where kv.0 == "ACL" {
         value = PFACL(dictionary: acl)
      }
      
      parseObject[kv.0] = value
    }
    
    //let parseObject = PFObject(className: className, dictionary: dictionary)
    parseObject.objectId = objectId
    
    // Let parse SDK think it was updated from the server
    parseObject.cleanupOperationQueue()
    return parseObject
  }
  
  func cleanupOperationQueue() {
    if let operationSetQueue = self.valueForKey("operationSetQueue") as? [AnyObject] where operationSetQueue.count == 1 {
      operationSetQueue.first?.setValue(NSMutableDictionary(), forKey: "_dictionary")
    }
    let data = self.valueForKeyPath("_estimatedData._dataDictionary") as! JSONObject
    self.setValue(data, forKeyPath: "_pfinternal_state._serverData")
    self.setValue(self.createdAt, forKeyPath: "_pfinternal_state._createdAt")
    self.setValue(self.updatedAt, forKeyPath: "_pfinternal_state._updatedAt")
  }

}