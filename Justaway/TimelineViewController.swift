import UIKit
import SwifteriOS
import EventBox

class TimelineViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var scrollWrapperView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var streamingStatusLabel: UILabel!
    @IBOutlet weak var streamingView: UIView!
    @IBOutlet weak var streamingButton: StreamingButton!
    @IBOutlet weak var tabWraperView: UIView!
    @IBOutlet weak var tabCurrentMaskLeftConstraint: NSLayoutConstraint!
    
    var settingsViewController: SettingsViewController!
    var tableViewControllers = [TimelineTableViewController]()
    var tabButtons = [MenuButton]()
    var setupView = false
    var userID = ""
    var currentPage = 0
    
    struct Static {
        private static let connectionQueue = NSOperationQueue().serial()
    }
    
    override var nibName: String {
        return "TimelineViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !setupView {
            setupView = true
            configureView()
            
            // ViewDidDisappear is performed When you view the ProfileViewController.
            configureEvent()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    deinit {
        EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        settingsViewController = SettingsViewController()
        ViewTools.addSubviewWithEqual(self.view, view: settingsViewController.view)
        
        if let account = AccountSettingsStore.get() {
            userID = account.account().userID
            ImageLoaderClient.displayTitleIcon(account.account().profileImageURL, imageView: iconImageView)
        }
        
        let size = scrollWrapperView.frame.size
        let contentView = UIView(frame: CGRectMake(0, 0, size.width * 3, size.height))
        
        for i in 0 ... 2 {
            let vc: TimelineTableViewController = i == 0 ? HomeTimelineTableViewController() : i == 1 ? NotificationsViewController() : FavoritesTableViewController()
            vc.view.frame = CGRectMake(0, 0, size.width, size.height)
            let view = UIView(frame: CGRectMake(size.width * CGFloat(i), 0, size.width, size.height))
            view.addSubview(vc.view)
            contentView.addSubview(view)
            tableViewControllers.append(vc)
            
            if let favoritesTableViewController = vc as? FavoritesTableViewController {
                favoritesTableViewController.userID = userID
            }
            
            let button = MenuButton(type: UIButtonType.System)
            button.tag = i
            button.tintColor = UIColor.clearColor()
            button.titleLabel?.font = UIFont(name: "fontello", size: 20.0)
            button.frame = CGRectMake(58 * CGFloat(i), 0, 58, 50)
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
            button.contentVerticalAlignment = UIControlContentVerticalAlignment.Center
            button.setTitle(i == 0 ? "家" : i == 1 ? "鐘" : "★", forState: UIControlState.Normal)
            button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tabButton:"))
            
            let longPress = UILongPressGestureRecognizer(target: self, action: "refresh:")
            longPress.minimumPressDuration = 2.0;
            button.addGestureRecognizer(longPress)
            
            tabWraperView.addSubview(button)
            tabButtons.append(button)
        }
        
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.pagingEnabled = true
        scrollView.delegate = self
        
        iconImageView.userInteractionEnabled = true
        let iconGesture = UITapGestureRecognizer(target: self, action: "openProfile:")
        iconGesture.numberOfTapsRequired = 1
        iconImageView.addGestureRecognizer(iconGesture)
        
        streamingView.userInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: "streamingSwitch:")
        gesture.numberOfTapsRequired = 1
        streamingView.addGestureRecognizer(gesture)
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: TwitterAuthorizeNotification, handler: { _ in
            self.reset()
        })
        
        EventBox.onMainThread(self, name: EventAccountChanged, handler: { _ in
            self.reset()
        })
        
        EventBox.onMainThread(self, name: Twitter.Event.CreateStatus.rawValue, sender: nil) { n in
            let status = n.object as! TwitterStatus
            var page = 0
            for tableViewController in self.tableViewControllers {
                switch tableViewController {
                case let vc as StatusTableViewController:
                    if vc.accept(status) {
                        vc.renderData([status], mode: .TOP, handler: {})
                        if self.currentPage != page || !vc.adapter.isTop {
                            self.tabButtons[page].selected = true
                        }
                    }
                default:
                    break
                }
                page++
            }
        }
        
        EventBox.onMainThread(self, name: Twitter.Event.DestroyStatus.rawValue, sender: nil) { n in
            let statusID = n.object as! String
            var page = 0
            for tableViewController in self.tableViewControllers {
                switch tableViewController {
                case let vc as StatusTableViewController:
                    vc.eraseData(statusID, handler: {})
                default:
                    break
                }
                page++
            }
        }
        
        EventBox.onMainThread(self, name: Twitter.Event.StreamingStatusChanged.rawValue) { _ in
            switch Twitter.connectionStatus {
            case .CONNECTED:
                self.streamingStatusLabel.text = "connected"
                self.streamingButton.enabled = true
                self.streamingButton.selected = true
            case .CONNECTING:
                self.streamingStatusLabel.text = "connecting..."
                self.streamingButton.enabled = true
                self.streamingButton.selected = false
            case .DISCONNECTED:
                self.streamingStatusLabel.text = "disconnected"
                if Twitter.enableStreaming {
                    self.streamingButton.enabled = false
                    self.streamingButton.selected = false
                } else {
                    self.streamingButton.enabled = true
                    self.streamingButton.selected = false
                }
            case .DISCONNECTING:
                self.streamingStatusLabel.text = "disconnecting..."
                self.streamingButton.enabled = true
                self.streamingButton.selected = false
            }
        }
        
        EventBox.onMainThread(self, name: "timelineScrollToTop", handler: { _ in
            if let vc = self.tableViewControllers[self.currentPage] as? StatusTableViewController {
                if vc.adapter.isTop {
                    self.tabButtons[self.currentPage].selected = false
                }
            }
        })
    }
    
    func toggleStreaming() {
        
    }
    
    func reset() {
        if let account = AccountSettingsStore.get() {
            ImageLoaderClient.displayTitleIcon(account.account().profileImageURL, imageView: self.iconImageView)
            
            // other account
            if userID != account.account().userID {
                userID = account.account().userID
                for tableViewController in self.tableViewControllers {
                    switch tableViewController {
                    case let vc as StatusTableViewController:
                        vc.refresh()
                    default:
                        break
                    }
                }
            }
        }
        self.settingsViewController.hide()
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let page = Int((scrollView.contentOffset.x + (scrollWrapperView.frame.size.width / 2)) / scrollWrapperView.frame.size.width)
        if currentPage != page {
            currentPage = page
            self.highlightUpdate(page)
        }
        
    }
    
    // MARK: - Actions
    
    func highlightUpdate(page: Int) {
        
        tabCurrentMaskLeftConstraint.constant = CGFloat(page * 58)
        
        if let vc = tableViewControllers[currentPage] as? StatusTableViewController {
            if vc.adapter.isTop {
                tabButtons[currentPage].selected = false
            }
        }
    }
    
    func refresh(sender: UILongPressGestureRecognizer) {
        if (sender.state != .Began) {
            return
        }
        tableViewControllers[currentPage].refresh()
    }
    
    func openProfile(sender: UIView) {
        if let account = AccountSettingsStore.get()?.account() {
            ProfileViewController.show(TwitterUser(account))
        }
    }
    
    func streamingSwitch(sender: UIView) {
        StreamingAlert.show(sender)
    }
    
    func tabButton(sender: UITapGestureRecognizer) {
        if let page = sender.view?.tag {
            if currentPage == page {
                if let vc = tableViewControllers[page] as? StatusTableViewController {
                    vc.adapter.scrollToTop(vc.tableView)
                }
                tabButtons[page].selected = false
            } else {
                UIView.animateWithDuration(0.3, animations: { () -> Void in
                    self.scrollView.contentOffset = CGPointMake(self.scrollView.frame.size.width * CGFloat(page), 0)
                }, completion: { (flag) -> Void in
                    self.currentPage = page
                    self.highlightUpdate(page)
                })
            }
        }
    }
    
    @IBAction func showEditor(sender: UIButton) {
        EditorViewController.show()
    }
    
    @IBAction func showSettings(sender: UIButton) {
        settingsViewController.show()
    }
    
    @IBAction func showPocketCover(sender: UIButton) {
        PocketCoverViewController.show()
    }
    
}
