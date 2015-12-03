//
//  ViewModel.swift
//  RxRealm
//
//  Created by Carlos García on 03/12/15.
//  Copyright © 2015 Carlos García. All rights reserved.
//

import RealmSwift
import RxSwift
import RxRealm


enum ViewModelErrors: ErrorType {
    case RealmError
}

struct ListViewModel {
    
    let todos = BehaviorSubject<[ToDoItem]>(value: [])
    private let disposeBag = DisposeBag()
    
    func update() {
        Realm.rx_objects(ToDoItem)
            .map { results -> [ToDoItem] in
                return results.map { $0 }
            }
            .bindNext { xs in
                self.todos.on(.Next(xs))
            }
            .addDisposableTo(disposeBag)
    }
    
}