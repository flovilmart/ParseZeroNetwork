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
    if let acl = data["ACL"] as? JSONObject {
      dictionary["ACL"] = PFACL(dictionary: acl)
    }
    // Remove objectId
    dictionary["objectId"] = nil
    let parseObject = PFObject(className: className, dictionary: dictionary)
    parseObject.objectId = objectId
    
    // Let parse SDK think it was updated from the server
    parseObject.setValue(dictionary, forKeyPath: "_estimatedData._dataDictionary")
    parseObject.cleanupOperationQueue()
    return parseObject
  }
  
  func cleanupOperationQueue() {
    if let operationSetQueue = self.valueForKey("operationSetQueue") as? [AnyObject] where operationSetQueue.count == 1 {
      operationSetQueue.first?.setValue([:], forKey: "_dictionary")
    }
    let data = self.valueForKeyPath("_estimatedData._dataDictionary")
    self.setValue(data, forKeyPath: "_pfinternal_state._serverData")
    self.setValue(self.createdAt, forKeyPath: "_pfinternal_state._createdAt")
    self.setValue(self.updatedAt, forKeyPath: "_pfinternal_state._updatedAt")
  }

}