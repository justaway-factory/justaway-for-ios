//
//  ListMemberOfViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/3/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class ListMemberOfViewController: ListTableViewController {
    override func loadData(_ maxID: String?, success: @escaping ((_ lists: [TwitterList]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let userID = userID {
             Twitter.getListsMemberOf(userID, success: success, failure: failure)
        }
    }
}
