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
    
    let parseObject = PFObject(className: className)
    parseObject.updateWithDictionary(data)
    // Let parse SDK think it was updated from the server
    return parseObject
  }
  
  func updateWithDictionary(data:JSONObject) -> Self {
    var dictionary = data;

    // template date
    let updatedAt = dateFromString(dictionary["updatedAt"] as? String)
    let createdAt = dateFromString(dictionary["createdAt"] as? String)

    if let createdAt = createdAt  {
      self.setValue(createdAt, forKeyPath: "_pfinternal_state._createdAt")
    }
    if let updatedAt = updatedAt {
      self.setValue(updatedAt, forKeyPath: "_pfinternal_state._updatedAt")
    }
    if let objectId = dictionary["objectId"] as? String {
      self.setValue(objectId, forKeyPath: "_pfinternal_state._objectId")
    }
    
    // Remove Internals
    dictionary.removeValueForKey("updatedAt")
    dictionary.removeValueForKey("createdAt")
    dictionary.removeValueForKey("objectId")
    
    if let sUpdatedAt = self.updatedAt where sUpdatedAt.timeIntervalSince1970 >= updatedAt?.timeIntervalSince1970 {
      pzero_log("🐷 skipping update...", self.updatedAt, dictionary["updatedAt"])
      return self
    }
    

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
      
      self[kv.0] = value
    }
    self.cleanupOperationQueue()
    return self
  }
  
  func cleanupOperationQueue() {
    if let operationSetQueue = self.valueForKey("operationSetQueue") as? [AnyObject] where operationSetQueue.count == 1 {
      operationSetQueue.first?.setValue(NSMutableDictionary(), forKey: "_dictionary")
    }
    let data = self.valueForKeyPath("_estimatedData._dataDictionary") as! JSONObject
    self.setValue(data, forKeyPath: "_pfinternal_state._serverData")
  }

}