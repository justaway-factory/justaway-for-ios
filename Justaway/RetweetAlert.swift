//
//  RetweetAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/17/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class RetweetAlert {
    class func show(_ sender: UIView, status: TwitterStatus) {
        let actionSheet = UIAlertController()
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { action in
                actionSheet.dismiss(animated: true, completion: nil)
        }))
        Twitter.isRetweet(status.statusID) { (retweetedStatusID) -> Void in
            if let retweetedStatusID = retweetedStatusID {
                if retweetedStatusID != "0" {
                    actionSheet.addAction(UIAlertAction(
                        title: "Undo Retweet",
                        style: .destructive,
                        handler: { action in
                            Twitter.destroyRetweet(status.statusID, retweetedStatusID: retweetedStatusID)
                    }))
                }
            } else {
                actionSheet.addAction(UIAlertAction(
                    title: "Retweet",
                    style: .default,
                    handler: { action in
                        Twitter.createRetweet(status.statusID)
                }))
            }
            actionSheet.addAction(UIAlertAction(
                title: "Quote",
                style: .default,
                handler: { action in
                    Twitter.quoteURL(status)
            }))

            // iPad
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds

            AlertController.showViewController(actionSheet)
        }
    }
}
