//
//  EditViewController.swift
//  RxRealm
//
//  Created by Carlos García on 03/12/15.
//  Copyright © 2015 Carlos García. All rights reserved.
//

import UIKit
import RealmSwift
import RxSwift
import RxCocoa

class EditViewController: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var newItemText: String?
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doneButton.rx_tap
            .subscribeNext { [unowned self] in
                self.doneAction()
            }
            .addDisposableTo(disposeBag)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textField?.becomeFirstResponder()
    }
    
    private func doneAction() {
        if self.textField!.text!.utf8.count > 0 {
            let newTodoItem = ToDoItem()
            newTodoItem.name = self.textField!.text!
            Realm.rx_add([newTodoItem], update: false, thread: Realm.RealmThread.MainThread)
                .subscribeCompleted { [unowned self] in
                    self.navigationController?.popViewControllerAnimated(true)
                }
                .addDisposableTo(disposeBag)
        }
        
    }
}

extension EditViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        doneAction()
        return true
    }
}