//
//  PFObject+Additions.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-12-01.
//  Copyright © 2015 flovilmart. All rights reserved.
//

import Foundation
import Parse

extension PFObject {
  static func mockedServerObject(className: String, objectId:String,var data:JSONObject) -> PFObject {
    let parseObject = PFObject(className: className, dictionary: data)
    parseObject.objectId = objectId
    if let ACLDict = data["ACL"] as? JSONObject {
      let ACL = PFACL()
      for (k,v) in ACLDict {
        let setReadAccess = v["read"] as? Bool == true
        let setWriteAccess = v["write"] as? Bool == true
  
        if k == "*" {
          ACL.publicReadAccess = setReadAccess
          ACL.publicWriteAccess = setWriteAccess
        } else if let _ = k.rangeOfString("role:") {
          let roleName = k.stringByReplacingOccurrencesOfString("role:", withString: "")
          ACL.setReadAccess(setReadAccess, forRoleWithName: roleName)
          ACL.setWriteAccess(setWriteAccess, forRoleWithName: roleName)
        } else {
          ACL.setReadAccess(setReadAccess, forUserId: k)
          ACL.setWriteAccess(setWriteAccess, forUserId: k)
        }
      }
      parseObject.ACL = ACL
    }
    // Let parse SDK think it was updated from the server
    parseObject.setValue(data, forKeyPath: "_estimatedData._dataDictionary")
    parseObject.setValue(data, forKeyPath: "_pfinternal_state._serverData")
    parseObject.setValue(parseObject.createdAt, forKeyPath: "_pfinternal_state._createdAt")
    parseObject.setValue(parseObject.updatedAt, forKeyPath: "_pfinternal_state._updatedAt")
    
    return parseObject
  }
}