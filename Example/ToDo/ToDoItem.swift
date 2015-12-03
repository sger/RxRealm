//
//  ToDoItem.swift
//  RxRealm
//
//  Created by Carlos García on 03/12/15.
//  Copyright © 2015 Carlos García. All rights reserved.
//

import RealmSwift

class ToDoItem: Object {
    dynamic var name = ""
    dynamic var finished = false
}