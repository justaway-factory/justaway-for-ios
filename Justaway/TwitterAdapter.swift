//
//  TwitterAdapter.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/18/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import Async

class TwitterAdapter: NSObject {

    // MARK: Types

    enum RenderMode {
        case HEADER
        case TOP
        case BOTTOM
        case OVER
    }

    struct Row {
        let status: TwitterStatus?
        let message: TwitterMessage?
        let fontSize: CGFloat
        let height: CGFloat
        let textHeight: CGFloat
        let quotedTextHeight: CGFloat

        init(status: TwitterStatus, fontSize: CGFloat, height: CGFloat, textHeight: CGFloat, quotedTextHeight: CGFloat) {
            self.status = status
            self.message = nil
            self.fontSize = fontSize
            self.height = height
            self.textHeight = textHeight
            self.quotedTextHeight = quotedTextHeight
        }

        init(message: TwitterMessage, fontSize: CGFloat, height: CGFloat, textHeight: CGFloat) {
            self.status = nil
            self.message = message
            self.fontSize = fontSize
            self.height = height
            self.textHeight = textHeight
            self.quotedTextHeight = 0
        }

        init() {
            self.status = nil
            self.message = nil
            self.fontSize = 0
            self.height = 30
            self.textHeight = 0
            self.quotedTextHeight = 0
        }
    }

    // MARK: Properties

    var rows = [Row]()
    var layoutHeight = [TwitterStatusCellLayout: CGFloat]()
    var layoutHeightCell = [TwitterStatusCellLayout: TwitterStatusCell]()
    var footerView: UIView?
    var footerIndicatorView: UIActivityIndicatorView?
    var isTop: Bool = true
    var scrolling: Bool = false
    var didScrollToBottom: (Void -> Void)?
    var scrollCallback: ((scrollView: UIScrollView) -> Void)?
    let loadDataQueue = NSOperationQueue().serial()
    let mainQueue = NSOperationQueue().serial()
    var renderStatusStack = [TwitterStatus]()

    // MARK: Configuration

    func configureView(tableView: UITableView) {
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        tableView.separatorColor = ThemeController.currentTheme.cellSeparatorColor()
        tableView.delegate = self
        tableView.dataSource = self
    }

    // MARK: Initializers

    override init() {
        super.init()
        // copy paste tooltip
        EventBox.on(self, name: UIMenuControllerWillShowMenuNotification, sender: nil, queue: nil) { [weak self] (_) in
            self?.mainQueue.suspended = true
        }
        EventBox.on(self, name: UIMenuControllerDidHideMenuNotification, sender: nil, queue: nil) { [weak self] (_) in
            self?.mainQueue.suspended = false
        }
        EventBox.on(self, name: "applicationWillResignActive", sender: nil, queue: nil) { [weak self] (_) in
            self?.mainQueue.suspended = true
        }
        EventBox.on(self, name: "applicationDidBecomeActive", sender: nil, queue: nil) { [weak self] (_) in
            self?.mainQueue.suspended = false
        }
    }

    deinit {
        EventBox.off(self)
    }

    // MARK: Public Methods

    func scrollBegin() {
        if !scrolling {
            // NSLog("scrollBegin")
        }
        isTop = false
        scrolling = true
        loadDataQueue.suspended = true
        mainQueue.suspended = true
    }

    func scrollEnd(scrollView: UIScrollView) {
        if scrolling {
            // NSLog("scrollEnd isTop:\(scrollView.contentOffset.y + scrollView.contentInset.top <= 0)")
        }
        scrolling = false
        loadDataQueue.suspended = false
        mainQueue.suspended = false
        if let tableView = scrollView as? UITableView {
            renderImages(tableView)
        }
        isTop = scrollView.contentOffset.y + scrollView.contentInset.top <= 0 ? true : false
        let y = scrollView.contentOffset.y + scrollView.bounds.size.height - scrollView.contentInset.bottom
        let h = scrollView.contentSize.height
        let f = h - y
        if f < timelineHooterHeight && h > scrollView.bounds.size.height {
            didScrollToBottom?()
        }
        if isTop {
            EventBox.post("timelineScrollToTop")
        }
    }

    func scrollToTop(scrollView: UIScrollView) {
        scrollView.setContentOffset(CGPoint.init(x: 0, y: -scrollView.contentInset.top), animated: true)
    }

    func eraseData(tableView: UITableView, target: ((row: Row) -> Bool), handler: (() -> Void)?) {
        var deleteIndexPaths = [NSIndexPath]()
        var i = 0
        var newRows = [Row]()
        for row in self.rows {
            if target(row: row) {
                deleteIndexPaths.append(NSIndexPath(forRow: i, inSection: 0))
            } else {
                newRows.append(row)
            }
            i += 1
        }

        if deleteIndexPaths.count > 0 {
            CATransaction.begin()
            if let handler = handler {
                CATransaction.setCompletionBlock(handler)
            }
            tableView.beginUpdates()
            self.rows = newRows
            tableView.deleteRowsAtIndexPaths(deleteIndexPaths, withRowAnimation: .Fade)
            tableView.endUpdates()
            CATransaction.commit()
        } else {
            handler?()
        }
    }

    func renderImages(tableView: UITableView) {
        for cell in tableView.visibleCells {
            if let statusCell = cell as? TwitterStatusCell {
                if let status = statusCell.status {
                    statusCell.setImage(status)
                } else if let message = statusCell.message {
                    statusCell.setImage(message)
                }
            }
        }
    }

    func fontSizeApplied(tableView: UITableView, fontSize: CGFloat, rows: [Row]) {
        let op = MainBlockOperation { (op) -> Void in
            if var firstCell = tableView.visibleCells.first {
                var offset = tableView.contentOffset.y - firstCell.frame.origin.y + tableView.contentInset.top
                var firstPath: NSIndexPath

                // セルが半分以上隠れているている場合、2番目の表示セルを基準にする
                if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
                    if indexPathsForVisibleRows.count > 1 && offset > (firstCell.frame.size.height / 2) {
                        firstPath = indexPathsForVisibleRows[1]
                        firstCell = tableView.cellForRowAtIndexPath(firstPath)!
                        offset = tableView.contentOffset.y - firstCell.frame.origin.y + tableView.contentInset.top
                    } else {
                        firstPath = indexPathsForVisibleRows.first!
                    }

                    self.rows = rows

                    tableView.reloadData()
                    tableView.scrollToRowAtIndexPath(firstPath, atScrollPosition: .Top, animated: false)
                    tableView.setContentOffset(CGPoint.init(x: 0, y: tableView.contentOffset.y + offset), animated: false)
                }
            }
            op.finish()
        }
        mainQueue.addOperation(op)
    }
}

// MARK: - UITableViewDataSource

extension TwitterAdapter: UITableViewDataSource {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        if let status = row.status {
            return cellForRowAtIndexPath(tableView, indexPath: indexPath, row: row, status: status)
        } else if let message = row.message {
            return cellForRowAtIndexPath(tableView, indexPath: indexPath, row: row, message: message)
        } else {
            // swiftlint:disable:next force_cast
            let cell = tableView.dequeueReusableCellWithIdentifier("ShowMoreTweetsCell", forIndexPath: indexPath) as! ShowMoreTweetsCell
            cell.showMoreLabel.hidden = false
            cell.indicator.hidden = true
            return cell
        }
    }

    func cellForRowAtIndexPath(tableView: UITableView, indexPath: NSIndexPath, row: Row, status: TwitterStatus) -> UITableViewCell {
        let layout = TwitterStatusCellLayout.fromStatus(status)
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCellWithIdentifier(layout.rawValue, forIndexPath: indexPath) as! TwitterStatusCell

        if cell.textHeightConstraint.constant != row.textHeight {
            cell.textHeightConstraint.constant = row.textHeight
        }

        if let quotedStatusLabelHeightConstraint = cell.quotedStatusLabelHeightConstraint {
            if quotedStatusLabelHeightConstraint.constant != row.quotedTextHeight {
                quotedStatusLabelHeightConstraint.constant = row.quotedTextHeight
            }
        }

        if row.fontSize != cell.statusLabel.font?.pointSize ?? 0 {
            cell.statusLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }

        if let quotedStatusLabel = cell.quotedStatusLabel {
            if row.fontSize != quotedStatusLabel.font?.pointSize ?? 0 {
                quotedStatusLabel.font = UIFont.systemFontOfSize(row.fontSize)
            }
        }

        if let s = cell.status {
            if s.uniqueID == status.uniqueID {
                return cell
            }
        }

        cell.status = status
        cell.setLayout(layout)
        cell.setText(status)
        cell.setImage(status)

        return cell
    }

    func cellForRowAtIndexPath(tableView: UITableView, indexPath: NSIndexPath, row: Row, message: TwitterMessage) -> UITableViewCell {
        let layout = TwitterStatusCellLayout.fromMessage(message)
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCellWithIdentifier(layout.rawValue, forIndexPath: indexPath) as! TwitterStatusCell

        if cell.textHeightConstraint.constant != row.textHeight {
            cell.textHeightConstraint.constant = row.textHeight
        }

        if row.fontSize != cell.statusLabel.font?.pointSize ?? 0 {
            cell.statusLabel.font = UIFont.systemFontOfSize(row.fontSize)
        }

        if let m = cell.message {
            if m.id == message.id {
                return cell
            }
        }

        if let adapter = self as? TwitterMessageAdapter where adapter.threadMode {
            cell.threadMode = true
        }

        cell.message = message
        cell.setLayout(layout)
        cell.setText(message)
        cell.setImage(message)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension TwitterAdapter: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let row = rows[indexPath.row]
        return row.height
    }

    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return timelineHooterHeight
    }

    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if footerView == nil {
            footerView = TransparentView(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.size.width, height: timelineHooterHeight))
            footerIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: ThemeController.currentTheme.activityIndicatorStyle())
            footerView?.addSubview(footerIndicatorView!)
            footerIndicatorView?.hidesWhenStopped = true
            footerIndicatorView?.center = (footerView?.center)!
        }
        return footerView
    }
}

// MARK: - UIScrollViewDelegate

extension TwitterAdapter {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        scrollCallback?(scrollView: scrollView)
        if loadDataQueue.suspended {
            return
        }
        scrollBegin() // now scrolling
    }

    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        scrollBegin() // begin of flick scrolling
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate {
            return
        }
        scrollEnd(scrollView) // end of flick scrolling no deceleration
    }

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        scrollEnd(scrollView) // end of deceleration of flick scrolling
    }

    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        scrollEnd(scrollView) // end of setContentOffset
    }
}
