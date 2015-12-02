//
//  Logger.swift
//  ParseZero
//
//  Created by Florent Vilmart on 15-12-02.
//  Copyright © 2015 flovilmart. All rights reserved.
//

internal func pzero_log(item:Any...) {
  if ParseZero.trace {
    let its = item.map({ i -> String in
      String(i)
    })
    var items = ["ParseZero: "]
    items.appendContentsOf(its)
    print(its.joinWithSeparator(" "))
  }
}
