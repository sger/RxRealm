//
//  ViewController.swift
//  Example
//
//  Created by Carlos García on 03/12/15.
//  Copyright © 2015 Carlos García. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa


class ListViewController: UITableViewController {
    
    private let viewModel = ListViewModel()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = nil
        viewModel.todos
            .bindTo(tableView.rx_itemsWithCellFactory) { tv, index, todo -> UITableViewCell in
                let ip = NSIndexPath(forRow: index, inSection: 0)
                let cell = tv.dequeueReusableCellWithIdentifier("Cell", forIndexPath: ip)
                cell.textLabel?.text = todo.name
                return cell
            }
            .addDisposableTo(disposeBag)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.update()
    }
    
    
}