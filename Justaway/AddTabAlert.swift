//
//  AddTabAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 2/4/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import TwitterAPI

class AddTabAlert {
    class func show(sender: UIView, tabs: [Tab]) {
        let actionSheet =  UIAlertController(title: "Add Tab", message: nil, preferredStyle: .ActionSheet)
        if tabs.indexOf({ $0.type == .HomeTimline }) == nil {
            actionSheet.addAction(UIAlertAction(title: "Home", style: .Default, handler: { action in
                EventBox.post("addTab", sender: Tab.init(type: .HomeTimline, userID: "", arguments: [:]))
            }))
        }
        if tabs.indexOf({ $0.type == .Notifications }) == nil {
            actionSheet.addAction(UIAlertAction(title: "Notifications", style: .Default, handler: { action in
                EventBox.post("addTab", sender: Tab.init(type: .Notifications, userID: "", arguments: [:]))
            }))
        }
        if tabs.indexOf({ $0.type == .Favorites }) == nil {
            actionSheet.addAction(UIAlertAction(title: "Likes", style: .Default, handler: { action in
                EventBox.post("addTab", sender: Tab.init(type: .Favorites, userID: "", arguments: [:]))
            }))
        }
        if tabs.indexOf({ $0.type == .Messages }) == nil {
            if let account = AccountSettingsStore.get()?.account() {
                if let _ = account.client as? OAuthClient {
                    actionSheet.addAction(UIAlertAction(title: "Messages", style: .Default, handler: { action in
                        EventBox.post("addTab", sender: Tab.init(type: .Messages, userID: "", arguments: [:]))
                    }))
                }
            }
        }
        actionSheet.addAction(UIAlertAction(title: "Lists...", style: .Default, handler: { action in
            ChooseListsViewController.show()
        }))
        actionSheet.addAction(UIAlertAction(title: "Saved Searches...", style: .Default, handler: { action in
            SavedSearchesViewController.show()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }
}
