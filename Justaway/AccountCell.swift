//
//  AccountCell.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/24/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import TwitterAPI
import Async

class AccountCell: BackgroundTableViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var displayNameLabel: DisplayNameLable!
    @IBOutlet weak var screenNameLabel: ScreenNameLable!
    @IBOutlet weak var clientNameLabel: ClientNameLable!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var notificationButton: UIButton!
    @IBOutlet weak var notificationLabel: UILabel!

    var account: Account?

    // MARK: - View Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
    }

    // MARK: - Configuration

    func configureView() {
        selectionStyle = .none
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
        iconImageView.layer.cornerRadius = 6
        iconImageView.clipsToBounds = true
    }

    func setText() {
        guard let account = account else {
            return
        }
        displayNameLabel.text = account.name
        screenNameLabel.text = "@" + account.screenName
        if account.client as? OAuthClient == nil {
            clientNameLabel.text = "via iOS"
            messageLabel.text = "off"
            messageLabel.textColor = ThemeController.currentTheme.menuTextColor()
            messageButton.setTitleColor(ThemeController.currentTheme.menuTextColor(), for: UIControlState())
        } else {
            clientNameLabel.text = "via Justaway for iOS"
            messageLabel.text = "on"
            messageLabel.textColor = ThemeController.currentTheme.accountOptionEnabled()
            messageButton.setTitleColor(ThemeController.currentTheme.accountOptionEnabled(), for: UIControlState())
        }
        if account.exToken.isEmpty {
            notificationLabel.text = "off"
            notificationLabel.textColor = ThemeController.currentTheme.menuTextColor()
            notificationButton.setTitleColor(ThemeController.currentTheme.menuTextColor(), for: UIControlState())
        } else {
            notificationLabel.text = "on"
            notificationLabel.textColor = ThemeController.currentTheme.accountOptionEnabled()
            notificationButton.setTitleColor(ThemeController.currentTheme.accountOptionEnabled(), for: UIControlState())
        }
    }

    @IBAction func message(_ sender: UIButton) {
        if messageLabel.text == "on" {

        } else {
            let alert = UIAlertController(title: "Are you sure you want to use the DirectMessage?", message: "Additional authentication is required.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                Twitter.addOAuthAccount()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            AlertController.showViewController(alert)
        }
    }

    @IBAction func notification(_ sender: UIButton) {
        if notificationLabel.text == "on" {
            let alert = UIAlertController(title: "Are you sure you want the notification to Off?", message: "Also no longer use notification tab.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                if let account = self.account {
                    let url = URL(string: "https://justaway.info/api/revoke.json")!
                    var req = URLRequest.init(url: url)
                    req.httpMethod = "POST"
                    req.setValue(account.exToken, forHTTPHeaderField: "X-Justaway-API-Token")
                    URLSession.shared.dataTask(with: req, completionHandler: { (data, response, error) in
                        if let error = error {
                            Async.main {
                                ErrorAlert.show(error as NSError)
                            }
                        } else {
                            let newAccount = Account.init(account: account, exToken: "")
                            if let accountSettings = AccountSettingsStore.get() {
                                let newSettings = accountSettings.merge([newAccount])
                                AccountSettingsStore.save(newSettings)
                            }
                            self.account = newAccount
                            Async.main {
                                self.setText()
                            }
                        }
                    }) .resume()
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            AlertController.showViewController(alert)
        } else {
            let alert = UIAlertController(title: "Are you sure you want to use the Notification?", message: "Additional authentication is required.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                SafariExURLHandler.open()
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            AlertController.showViewController(alert)
        }
    }
}
