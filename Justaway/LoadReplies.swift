//
//  LoadReplies.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/16/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import SwiftyJSON

class LoadReplies {
    class func loadData(_ adapter: TwitterStatusAdapter, tableView: UITableView, sourceStatus: TwitterStatus) {
        if let inReplyToStatusID = sourceStatus.inReplyToStatusID {
            LoadReplies.loadStatus(adapter, tableView: tableView, statusID: inReplyToStatusID)
        }
        LoadReplies.searchStatus(adapter, tableView: tableView, sourceStatus: sourceStatus)
    }

    class func loadStatus(_ adapter: TwitterStatusAdapter, tableView: UITableView, statusID: String) {
        let success = { (statuses: [TwitterStatus]) -> Void in
            adapter.mainQueue.addOperation(MainBlockOperation({ (op) in
                adapter.renderData(tableView, statuses: statuses, mode: .top, handler: {
                    op.finish()
                })
            }))
            for status in statuses {
                if let inReplyToStatusID = status.inReplyToStatusID {
                    LoadReplies.loadStatus(adapter, tableView: tableView, statusID: inReplyToStatusID)
                }
            }
        }
        let failure = { (error: NSError) -> Void in
            ErrorAlert.show("Error", message: error.localizedDescription)
        }
        Twitter.getStatuses([statusID], success: success, failure: failure)
    }

    class func searchStatus(_ adapter: TwitterStatusAdapter, tableView: UITableView, sourceStatus: TwitterStatus) {
        var allStatuses = [TwitterStatus]()
        var isReplyIDs = [String: Bool]()
        isReplyIDs[sourceStatus.statusID] = true
        let lookupAlways = {
            let replies =
                allStatuses
                    .sorted { $0.0.statusID.longLongValue < $0.1.statusID.longLongValue }
                    .filter { status in
                        if let inReplyToStatusID = status.inReplyToStatusID, isReplyIDs[inReplyToStatusID] != nil && isReplyIDs[status.statusID] == nil {
                            isReplyIDs[status.statusID] = true
                            return true
                        } else {
                            return false
                        }
            }
            if replies.count > 0 {
                adapter.mainQueue.addOperation(MainBlockOperation({ (op) in
                    adapter.renderData(tableView, statuses: replies, mode: .bottom, handler: {
                        adapter.footerIndicatorView?.stopAnimating()
                        op.finish()
                    })
                }))
            } else {
                adapter.mainQueue.addOperation(MainBlockOperation({ (op) in
                    adapter.footerIndicatorView?.stopAnimating()
                    op.finish()
                }))
            }
        }
        let lookupSuccess = { (statuses: [TwitterStatus]) in
            allStatuses += statuses
            lookupAlways()
        }
        let lookupFailure = { (error: NSError) in
            lookupAlways()
        }
        let fromAlways = {
            var loadIDs = [String: Bool]()
            for status in allStatuses {
                loadIDs[status.statusID] = true
            }
            var lookupIDs = [String]()
            for status in allStatuses {
                if let inReplyToStatusID = status.inReplyToStatusID, loadIDs[inReplyToStatusID] == nil {
                    loadIDs[inReplyToStatusID] = true
                    lookupIDs.append(inReplyToStatusID)
                    if lookupIDs.count >= 100 {
                        break
                    }
                }
            }
            if lookupIDs.count > 0 {
                Twitter.getStatuses(lookupIDs, success: lookupSuccess, failure: lookupFailure)
            } else {
                lookupAlways()
            }
        }
        let fromSuccess = { (statuses: [TwitterStatus], searchMetadata: [String: JSON]) in
            allStatuses += statuses
            fromAlways()
        }
        let fromFailure = { (error: NSError) in
            fromAlways()
        }
        let fromQuery = "from:\(sourceStatus.user.screenName) AND filter:replies"
        let toAlways = {
            Twitter.getSearchTweets(fromQuery, maxID: nil, sinceID: sourceStatus.statusID, excludeRetweets: true, success: fromSuccess, failure: fromFailure)
        }
        let toSuccess = { (statuses: [TwitterStatus], searchMetadata: [String: JSON]) in
            allStatuses += statuses
            toAlways()
        }
        let toFailure = { (error: NSError) in
            toAlways()
        }
        let toQuery = "to:\(sourceStatus.user.screenName) AND filter:replies"
        Twitter.getSearchTweets(toQuery, maxID: nil, sinceID: sourceStatus.statusID, excludeRetweets: true, success: toSuccess, failure: toFailure)
    }
}
