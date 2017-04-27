import UIKit
import EventBox

class TimelineViewController: UIViewController, UIScrollViewDelegate {

    // MARK: Properties

    @IBOutlet weak var titleLabelView: TextLable!
    @IBOutlet weak var scrollWrapperView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var streamingButton: StreamingButton!
    @IBOutlet weak var tabScrollView: UIScrollView!
    @IBOutlet weak var tabWrapperView: UIView!
    @IBOutlet weak var tabCurrentMaskLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var tabWrapperWidthConstraint: NSLayoutConstraint!

    var swipeGestureRecognizer: UISwipeGestureRecognizer?
    var settingsViewController: SettingsViewController!
    var sideMenuViewController: SideMenuViewController!
    var tableViewControllers = [TimelineTableViewController]()
    var tabButtons = [TabButton]()
    var titles = [String]()
    var setupView = false
    var userID = ""
    var currentPage = 0
    var isActive = true
    var rederStatusStock = [TwitterStatus]()
    var eraseStatusIDStock = [String]()

    struct Static {
        fileprivate static let connectionQueue = OperationQueue().serial()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    deinit {
        EventBox.off(self)
    }

    // MARK: - Configuration

    func configureView() {
        settingsViewController = SettingsViewController()
        sideMenuViewController = SideMenuViewController()

        sideMenuViewController.settingsViewController = settingsViewController

        ViewTools.addSubviewWithEqual(self.view, view: settingsViewController.view)

        if let account = AccountSettingsStore.get()?.account() {
            userID = account.userID
        }

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(TimelineViewController.showSideMenu))
        swipe.numberOfTouchesRequired = 1
        swipe.direction = .right
        scrollView.panGestureRecognizer.require(toFail: swipe)
        scrollView.addGestureRecognizer(swipe)
        swipeGestureRecognizer = swipe

        configureTimelineView()
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    func configureTimelineView() {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }

        Relationship.setup(account)

        currentPage = min(currentPage, account.tabs.count - 1)

        var vcCache = [String: TimelineTableViewController]()
        var buttonCache = [String: TabButton]()
        for (index, tableViewController) in tableViewControllers.enumerated() {
            switch tableViewController {
            case let vc as HomeTimelineTableViewController:
                vcCache["HomeTimelineTableViewController"] = vc
            case let vc as UserTimelineTableViewController:
                if let userID = vc.userID {
                    vcCache["UserTimelineTableViewController-" + userID] = vc
                }
            case let vc as SearchesTableViewController:
                if let keyword = vc.keyword {
                    vcCache["SearchesTableViewController-" + keyword] = vc
                    buttonCache["SearchesTableViewController-" + keyword] = tabButtons[index]
                }
            case let vc as NotificationsViewController:
                vcCache["NotificationsViewController"] = vc
            case let vc as MentionsTableViewController:
                vcCache["MentionsTableViewController"] = vc
            case let vc as FavoritesTableViewController:
                vcCache["FavoritesTableViewController"] = vc
            case let vc as ListsTimelineTableViewController:
                if let list = vc.list {
                    vcCache["UserTimelineTableViewController-" + list.id] = vc
                }
            case let vc as MessagesTableViewController:
                vcCache["MessagesTableViewController"] = vc
            default:
                break
            }
        }
        tableViewControllers.removeAll()

        for view in tabWrapperView.subviews {
            if view.tag >= 0 {
                view.removeFromSuperview()
            }
        }

        var newTabButtons = [TabButton]()
        var newTitles = [String]()

        let size = scrollWrapperView.frame.size
        let contentView = UIView(frame: CGRect.init(x: 0, y: 0, width: size.width * CGFloat(account.tabs.count), height: size.height))
        tabWrapperWidthConstraint.constant = 58 * CGFloat(account.tabs.count)

        for (i, tab) in account.tabs.enumerated() {
            let vc: TimelineTableViewController
            let icon: String
            let title: String
            var cacheButton: TabButton?
            switch tab.type {
            case .HomeTimline:
                vc = vcCache["HomeTimelineTableViewController"] ?? HomeTimelineTableViewController()
                icon = "家"
                title = "Home"
            case .UserTimline:
                let uvc = vcCache["UserTimelineTableViewController-" + tab.user.userID] as? UserTimelineTableViewController ?? UserTimelineTableViewController()
                uvc.userID = tab.user.userID
                vc = uvc
                icon = "人"
                title = tab.user.name + " / @" + tab.user.screenName
            case .Notifications:
                vc = vcCache["NotificationsViewController"] ?? NotificationsViewController()
                icon = "鐘"
                title = "Notifications"
            case .Mentions:
                vc = vcCache["MentionsTableViewController"] ?? MentionsTableViewController()
                icon = "@"
                title = "Mentions"

            case .Favorites:
                vc = vcCache["FavoritesTableViewController"] ?? FavoritesTableViewController()
                icon = "好"
                title = "Favorites"
            case .Searches:
                let keyword = tab.keyword
                let svc = vcCache["SearchesTableViewController-" + keyword] as? SearchesTableViewController ?? SearchesTableViewController()
                svc.keyword = keyword
                cacheButton = buttonCache["SearchesTableViewController-" + keyword]
                cacheButton?.tag = i
                cacheButton?.frame = CGRect.init(x: 58 * CGFloat(i), y: 0, width: 58, height: 50)
                vc = svc
                icon = "探"
                title = keyword
            case .Lists:
                let list = tab.list
                let svc = vcCache["ListsTimelineTableViewController-" + list.id] as? ListsTimelineTableViewController ?? ListsTimelineTableViewController()
                svc.list = list
                vc = svc
                icon = "欄"
                title = list.name
            case .Messages:
                vc = vcCache["MessagesTableViewController"] ?? MessagesTableViewController()
                icon = "文"
                title = "Messages"
            }
            vc.tableView.contentInset = UIEdgeInsets(top: 60, left: 0, bottom: 0, right: 0)
            vc.view.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            let view = UIView(frame: CGRect(x: size.width * CGFloat(i), y: 0, width: size.width, height: size.height))
            view.addSubview(vc.view)
            contentView.addSubview(view)
            tableViewControllers.append(vc)

            if let favoritesTableViewController = vc as? FavoritesTableViewController {
                favoritesTableViewController.userID = userID
            }

            vc.adapter.scrollEnd(vc.tableView)

            let button = cacheButton ?? createTabButton(i, icon: icon)
            tabWrapperView.addSubview(button)
            newTabButtons.append(button)
            newTitles.append(title)

            if let adapter = vc.adapter as? TwitterStatusAdapter {
                let page = i
                let isSearches = tab.type == .Searches
                adapter.renderDataCallback = { (statuses: [TwitterStatus], mode: TwitterStatusAdapter.RenderMode) in
                    if statuses.count > 0 && mode == .header {
                        NSLog("page:\(page) count:\(statuses.count)")
                        self.tabButtons[page].isSelected = true
                    }
                    if statuses.count > 0 && mode == .top && isSearches {
                        if self.currentPage != page {
                            self.tabButtons[page].isSelected = true
                        } else {
                            let buttonIndex = page
                            let operation = MainBlockOperation { (operation) -> Void in
                                if !vc.adapter.isTop {
                                    self.tabButtons[buttonIndex].isSelected = true
                                }
                                operation.finish()
                            }
                            vc.adapter.mainQueue.addOperation(operation)
                        }
                    }
                }
            }
        }

        tabButtons = newTabButtons
        titles = newTitles
        tabScrollView.contentSize = tabWrapperView.frame.size

        for view in scrollView.subviews {
            view.removeFromSuperview()
        }
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size
        scrollView.isPagingEnabled = true
        scrollView.delegate = self
        scrollView.contentOffset = CGPoint.init(x: scrollView.frame.size.width * CGFloat(currentPage), y: 0)

        highlightUpdate(currentPage)
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
    // swiftlint:enable function_body_length

    func createTabButton(_ index: Int, icon: String) -> TabButton {
        let button = TabButton(type: .system)
        button.tag = index
        button.tintColor = UIColor.clear
        button.titleLabel?.font = UIFont(name: "fontello", size: 20.0)
        button.frame = CGRect.init(x: 58 * CGFloat(index), y: 0, width: 58, height: 50)
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignment.center
        button.contentVerticalAlignment = UIControlContentVerticalAlignment.center
        button.setTitle(icon, for: UIControlState())
        button.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(TimelineViewController.tabButton(_:))))
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(TimelineViewController.tabMenu(_:)))
        longPress.minimumPressDuration = 0.5
        button.addGestureRecognizer(longPress)
        return button
    }

    func configureEvent() {
        EventBox.onMainThread(self, name: eventTabChanged, handler: { _ in
            self.configureTimelineView()
        })

        EventBox.onMainThread(self, name: twitterAuthorizeNotification, handler: { _ in
            self.reset()
        })

        EventBox.onMainThread(self, name: eventAccountChanged, handler: { _ in
            self.reset()
            self.settingsViewController.hide()
        })

        configureCreateStatusEvent()

        configureDestroyStatusEvent()

        configureStreamingEvent()

        EventBox.onMainThread(self, name: Notification.Name(rawValue: "timelineScrollToTop"), handler: { _ in
            if self.tableViewControllers.count <= self.currentPage {
                return
            }
            let vc = self.tableViewControllers[self.currentPage]
            if vc.adapter.isTop {
                self.tabButtons[self.currentPage].isSelected = false
            }
        })

        EventBox.onBackgroundThread(self, name: Notification.Name(rawValue: "applicationDidEnterBackground")) { (n) -> Void in
            for tableViewController in self.tableViewControllers {
                tableViewController.saveCache()
            }
        }
        EventBox.on(self, name: Notification.Name(rawValue: "applicationWillResignActive"), sender: nil, queue: nil) { [weak self] (_) in
            self?.isActive = false
        }
        EventBox.on(self, name: Notification.Name(rawValue: "applicationDidBecomeActive"), sender: nil, queue: nil) { [weak self] (_) in
            guard let `self` = self else {
                return
            }
            self.isActive = true
            if self.rederStatusStock.count > 0 {
                self.createStatuses(self.rederStatusStock.filter({ !self.eraseStatusIDStock.contains($0.statusID) }).reversed())
                self.rederStatusStock.removeAll()
            }
            if self.eraseStatusIDStock.count > 0 {
                self.destroyStatuses(self.eraseStatusIDStock)
                self.eraseStatusIDStock.removeAll()
            }
        }
    }

    func configureCreateStatusEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateStatus.Name(), sender: nil) { n in
            guard let status = n.object as? TwitterStatus else {
                return
            }
            if self.isActive {
                self.createStatuses([status])
            } else {
                self.rederStatusStock.append(status)
            }
        }
    }

    func createStatuses(_ statuses: [TwitterStatus]) {
        var page = 0
        for tableViewController in self.tableViewControllers {
            switch tableViewController {
            case let vc as StatusTableViewController:
                let acceptStatuses = statuses.filter({ vc.accept($0) })
                if acceptStatuses.count > 0 {
                    vc.renderData(acceptStatuses, mode: .top, handler: {})
                    for status in acceptStatuses {
                        let actionedByUserID = status.actionedBy?.userID ?? ""
                        let actionedByMe = AccountSettingsStore.get()?.isMe(actionedByUserID) ?? false
                        if !actionedByMe {
                            if self.currentPage != page {
                                self.tabButtons[page].isSelected = true
                                break
                            } else {
                                let buttonIndex = page
                                let operation = MainBlockOperation { (operation) -> Void in
                                    if !vc.adapter.isTop {
                                        self.tabButtons[buttonIndex].isSelected = true
                                    }
                                    operation.finish()
                                }
                                vc.adapter.mainQueue.addOperation(operation)
                                break
                            }
                        }
                    }
                    vc.saveCacheSchedule()
                }
            default:
                break
            }
            page += 1
        }
    }

    func configureDestroyStatusEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.DestroyStatus.Name(), sender: nil) { n in
            guard let statusID = n.object as? String else {
                return
            }
            if self.isActive {
                self.destroyStatuses([statusID])
            } else {
                self.eraseStatusIDStock.append(statusID)
            }
        }
    }

    func destroyStatuses(_ statusIDs: [String]) {
        var page = 0
        for tableViewController in self.tableViewControllers {
            switch tableViewController {
            case let vc as StatusTableViewController:
                for statusID in statusIDs {
                    vc.eraseData(statusID, handler: {})
                }
            default:
                break
            }
            page += 1
        }
    }

    func configureStreamingEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.StreamingStatusChanged.Name()) { _ in
            self.sideMenuViewController.updateStreamingButtonTitle()
        }
    }

    func toggleStreaming() {

    }

    func reset() {
        if let account = AccountSettingsStore.get()?.account() {

            // other account
            if userID != account.userID {
                userID = account.userID
                configureTimelineView()
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
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int((scrollView.contentOffset.x + (scrollWrapperView.frame.size.width / 2)) / scrollWrapperView.frame.size.width)
        if currentPage != page {
            currentPage = page
            self.highlightUpdate(page)
        }

    }

    // MARK: - Actions

    func showSideMenu() {
        if let account = AccountSettingsStore.get()?.account() {
            sideMenuViewController.show(account)
        }
    }

    func highlightUpdate(_ page: Int) {

        swipeGestureRecognizer?.isEnabled = page == 0

        tabCurrentMaskLeftConstraint.constant = CGFloat(page * 58)

        let vc = tableViewControllers[currentPage]
        if vc.adapter.isTop {
            tabButtons[currentPage].isSelected = false
        }

        titleLabelView.text = titles[currentPage]
    }

    func tabMenu(_ sender: UILongPressGestureRecognizer) {
        if sender.state != .began {
            return
        }
        guard let view = sender.view else {
            return
        }
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        let index = view.tag
        if index >= account.tabs.count {
            return
        }

        let actionSheet =  UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Refresh", style: .default, handler: { action in
            self.tableViewControllers[index].refresh()
        }))

        let tab = account.tabs[index]
        if tab.type == .Searches {
            actionSheet.addAction(UIAlertAction(title: "Tweet with " + tab.keyword, style: .default, handler: { action in
                EditorViewController.show(" " + tab.keyword, range: NSRange(location: 0, length: 0), inReplyToStatus: nil)
            }))
            if let vc = tableViewControllers[index] as? SearchesTableViewController {
                let tabButton = tabButtons[index]
                vc.addStreamingAction(actionSheet, tabButton: tabButton)
            }
        } else if tab.type == .UserTimline {
            actionSheet.addAction(UIAlertAction(title: "Reply to @" + tab.user.screenName, style: .default, handler: { action in
                let prefix = "@\(tab.user.screenName) "
                let range = NSRange.init(location: prefix.characters.count, length: 0)
                EditorViewController.show(prefix, range: range, inReplyToStatus: nil)
            }))
        } else if tab.type == .Notifications {
            if account.exToken.isEmpty {
                actionSheet.addAction(UIAlertAction(title: "Enable Notification", style: .default, handler: { action in
                    SafariExURLHandler.open()
                }))
            }
        }

        actionSheet.addAction(UIAlertAction(title: "Tab Settings", style: .default, handler: { action in
            TabSettingsViewController.show()
        }))

        if account.tabs.count > 1 {
            actionSheet.addAction(UIAlertAction(title: "Remove tab", style: .destructive, handler: { action in
                var tabs = account.tabs
                tabs.remove(at: index)
                let newAccount = Account(account: account, tabs: tabs)
                if let settings = AccountSettingsStore.get() {
                    let accounts = settings.accounts.map({ $0.userID == newAccount.userID ? newAccount : $0 })
                    _ = AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                    EventBox.post(eventTabChanged)
                }
            }))
        }

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // iPad
        actionSheet.popoverPresentationController?.sourceView = view
        actionSheet.popoverPresentationController?.sourceRect = view.bounds

        AlertController.showViewController(actionSheet)
    }

    func tabButton(_ sender: UITapGestureRecognizer) {
        if let page = sender.view?.tag {
            if currentPage == page {
                let vc = tableViewControllers[page]
                vc.adapter.scrollToTop(vc.tableView)
                tabButtons[page].isSelected = false
            } else {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    self.scrollView.contentOffset = CGPoint.init(x: self.scrollView.frame.size.width * CGFloat(page), y: 0)
                }, completion: { (flag) -> Void in
                    self.currentPage = page
                    self.highlightUpdate(page)
                })
            }
        }
    }

    @IBAction func search(_ sender: AnyObject) {
        SearchViewController.show("")
    }

    @IBAction func openSidemenu(_ sender: AnyObject) {
        showSideMenu()
    }

    @IBAction func streamingSwitch(_ sender: UIButton) {
        StreamingAlert.show(sender)
    }

    @IBAction func showEditor(_ sender: UIButton) {
        EditorViewController.show()
    }

    @IBAction func showSettings(_ sender: UIButton) {
        settingsViewController.show()
    }

    @IBAction func showPocketCover(_ sender: UIButton) {
        PocketCoverViewController.show()
    }

}
