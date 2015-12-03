//
//  RxRealm.swift
//  RxRealm
//
//  Created by Carlos García on 03/12/15.
//  Copyright © 2015 Carlos García. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

// MARK: - Realm extension that adds a reactive interface to Realm
public extension Realm {
    
    /**
     Enum that represents a Realm within a thread (used for operations)
     
     - MainThread:             Operations executed in the Main Thread Realm. Completion called in Main Thread
     - BackgroundThread        Operations executed in a New Background Thread Realm. Completion called in the Main Thread
     - SameThread:             Operations executed in the given Background Thread Realm. Completion called in the same Thread
     */
    enum RealmThread {
        case MainThread
        case BackgroundThread
        case SameThread(Realm)
    }
    
    enum RealmError: ErrorType {
        case WrongThread
        case InvalidRealm
        case InvalidReadThread
    }
    
    // MARK: - Helpers
    
    /// Realm save closure
    typealias OperationClosure = (realm: Realm) -> ()
    
    /// Executes the given operation passing the read to the operation block. Once it's completed the completion closure is called passing error in case of something went wrong
    private static func realmOperationInThread(thread: RealmThread, writeOperation: Bool, completion: RealmError? -> Void, operation: OperationClosure) {
        switch thread {
        case .MainThread:
            if !NSThread.isMainThread() {
                completion(.WrongThread)
            }
            do {
                let realm = try Realm()
                if writeOperation { realm.beginWrite() }
                operation(realm: realm)
                if writeOperation { try! realm.commitWrite() }
                completion(nil)
            }
            catch {
                completion(.InvalidRealm)
            }
        case .BackgroundThread:
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                do {
                    let realm = try Realm()
                    if writeOperation { realm.beginWrite() }
                    operation(realm: realm)
                    if writeOperation { try! realm.commitWrite() }
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(nil)
                    }
                }
                catch {
                    dispatch_async(dispatch_get_main_queue()) {
                        completion(.InvalidRealm)
                    }
                }
            }
        case .SameThread(let realm):
            if writeOperation { realm.beginWrite() }
            operation(realm: realm)
            if writeOperation { try! realm.commitWrite() }
            completion(nil)
        }
    }
    
    /// Generates the Observable that executes the given write operation
    private static func realmWriteOperationObservable(thread thread: RealmThread, writeOperation: Bool, operation: OperationClosure) -> Observable<Void> {
        return RxSwift.create { observer -> Disposable in
            Realm.realmOperationInThread(thread, writeOperation: writeOperation, completion: { error in
                if let error = error {
                    observer.onError(error)
                }
                observer.onCompleted()
                }, operation: operation)
            return NopDisposable.instance
        }
    }
    
    
    // MARK: - Creation
    
    /**
    Add the objects to Realm
    
    :param: objects    objects to be added
    :param: update     true if they have to be updated in case of existing under the same primary key
    :param: thread     RealmThread where the operation will be executed
    
    :returns: Observable that fires operation
    */
    static func rx_add<S: SequenceType where S.Generator.Element: Object>(objects: S, update: Bool = false, thread: RealmThread = .BackgroundThread) -> Observable<Void> {
        return realmWriteOperationObservable(thread: thread, writeOperation: true, operation: { (realm: Realm) -> () in
            realm.add(objects)
        })
    }
    
    /**
     Creates the object in Realm
     
     :param: type       object type
     :param: value      object value
     :param: update     true if the object has to be update in case of existing under the same primary key
     :param: thread     RealmThread where the operation will be executed
     
     :returns: Observable that fires the operation
     */
    static func rx_create<T: Object>(type: T.Type, value: AnyObject = [:], update: Bool = false, thread: RealmThread = .BackgroundThread) -> Observable<Void> {
        return realmWriteOperationObservable(thread: thread, writeOperation: true, operation: { (realm: Realm) -> () in
            realm.create(type, value: value, update: update)
        })
    }
    
    
    // MARK: - Deletion
    
    /**
    Deletes the object from Realm
    
    :param: object     object to be deleted
    :param: thread     RealmThread where the operation will be executed
    
    :returns: Observable that fires the operation
    */
    static func rx_delete(object: Object, thread: RealmThread) -> Observable<Void> {
        return realmWriteOperationObservable(thread: thread, writeOperation: true, operation: { (realm: Realm) -> () in
            realm.delete(object)
        })
    }
    
    /**
     Deletes the objects from Realm
     
     :param: objects objects to be deleted
     :param: thread  RealmThread where the operation will be executed
     
     :returns: Observable that fires the operation
     */
    static func rx_delete<S: SequenceType where S.Generator.Element: Object>(objects: S, thread: RealmThread) -> Observable<Void> {
        return realmWriteOperationObservable(thread: thread, writeOperation: true, operation: { (realm: Realm) -> () in
            realm.delete(objects)
        })
    }
    
    /**
     Deletes the objects from Realm
     
     :param: objects objects to be deleted
     :param: thread  RealmThread where the operation will be executed
     
     :returns: Observable that fires the operation
     */
    static func rx_delete<T: Object>(objects: List<T>, thread: RealmThread) -> Observable<Void> {
        return realmWriteOperationObservable(thread: thread, writeOperation: true, operation: { (realm: Realm) -> () in
            realm.delete(objects)
        })
    }
    
    /**
     Deletes the objects from Realm
     
     :param: objects objects to be deleted
     :param: thread  RealmThread where the operation will be executed
     
     :returns: Observable that fires the operation
     */
    static func rx_delete<T: Object>(objects: Results<T>, thread: RealmThread) ->  Observable<Void> {
        return realmWriteOperationObservable(thread: thread, writeOperation: true, operation: { (realm: Realm) -> () in
            realm.delete(objects)
        })
    }
    
    /**
     Deletes all the objects from Realm
     
     :returns: Observable that fires the operation
     */
    static func rx_deleteAll(thread: RealmThread) -> Observable<Void> {
        return realmWriteOperationObservable(thread: thread, writeOperation: true, operation: { (realm: Realm) -> () in
            realm.deleteAll()
        })
    }
    
    
    // MARK: - Querying
    
    /**
    Returns objects of the given type
    Note: This Observable has to be subscribed in the Main Thread
    
    :param: type object type
    
    :returns: Observable that fires the operation
    */
    static func rx_objects<T: Object>(type: T.Type) -> Observable<RealmSwift.Results<T>> {
        return RxSwift.create { observer -> Disposable in
            if !NSThread.isMainThread() {
                observer.onError(RealmError.InvalidReadThread)
            }
            else {
                do {
                    let realm = try Realm()
                    observer.onNext(realm.objects(type))
                    observer.onCompleted()
                }
                catch  {
                    observer.onError(RealmError.InvalidRealm)
                }
            }
            return NopDisposable.instance
        }
    }
    
    /**
     Returns the object with the given primary key
     
     :param: type object type
     :param: key  primary key
     
     :returns: Observable that fires the operation
     */
    static func rx_objectForPrimaryKey<T: Object>(type: T.Type, key: AnyObject) -> Observable<T?> {
        return RxSwift.create { observer -> Disposable in
            if !NSThread.isMainThread() {
                observer.onError(RealmError.InvalidReadThread)
            }
            else {
                do {
                    let realm = try Realm()
                    observer.onNext(realm.objectForPrimaryKey(type, key: key))
                    observer.onCompleted()
                }
                catch  {
                    observer.onError(RealmError.InvalidRealm)
                }
            }
            return NopDisposable.instance
        }
    }
    
}


// MARK: - Reactive Operators

/**
Filters the Observable of Results<T> applying an NSPredicate

:param: predicate filtering predicate

:returns: filtered Observable
*/
public func filter<T: Object>(predicate: NSPredicate) -> Observable<Results<T>> -> Observable<Results<T>> {
    return { (observable: Observable<Results<T>>) -> Observable<Results<T>> in
        return observable
            .map {
                $0.filter(predicate)
            }
    }
}

/**
 Filters the Observable of Results<T> applying a predicate string
 
 :param: predicateSring filtering predicate
 
 :returns: filtered Observable
 */
public func filter<T>(predicateString: String) -> Observable<Results<T>> -> Observable<Results<T>> {
    return { (observable: Observable<Results<T>>) -> Observable<Results<T>> in
        return observable
            .map {
                $0.filter(predicateString)
            }
    }
}

/**
 Sorts the Observable of Results<T> using a key an the ascending value
 
 :param: key key the results will be sorted by
 :param: ascending true if the results sort order is ascending
 
 :returns: sorted Observable
 */
public func sorted<T>(key: String, ascending: Bool = true) -> Observable<Results<T>> -> Observable<Results<T>> {
    return { (observable: Observable<Results<T>>) -> Observable<Results<T>> in
        return observable
            .map {
                $0.sorted(key, ascending: ascending)
            }
    }
}

