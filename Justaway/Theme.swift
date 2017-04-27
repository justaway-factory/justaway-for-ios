//
//  Theme.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/8/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import KeyClip

protocol Theme {

    func name() -> String

    func statusBarStyle() -> UIStatusBarStyle
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle
    func showMoreTweetIndicatorStyle() -> UIActivityIndicatorViewStyle
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle

    func mainBackgroundColor() -> UIColor
    func mainHighlightBackgroundColor() -> UIColor
    func titleTextColor() -> UIColor
    func bodyTextColor() -> UIColor
    func cellSeparatorColor() -> UIColor

    func sideMenuBackgroundColor() -> UIColor
    func switchTintColor() -> UIColor

    func displayNameTextColor() -> UIColor
    func screenNameTextColor() -> UIColor
    func relativeDateTextColor() -> UIColor
    func absoluteDateTextColor() -> UIColor
    func clientNameTextColor() -> UIColor

    func menuBackgroundColor() -> UIColor
    func menuTextColor() -> UIColor
    func menuHighlightedTextColor() -> UIColor
    func menuSelectedTextColor() -> UIColor
    func menuDisabledTextColor() -> UIColor

    func showMoreTweetBackgroundColor() -> UIColor
    func showMoreTweetLabelTextColor() -> UIColor

    func buttonNormal() -> UIColor
    func retweetButtonSelected() -> UIColor
    func favoritesButtonSelected() -> UIColor
    func followButtonSelected() -> UIColor

    func streamingConnected() -> UIColor
    func streamingError() -> UIColor

    func accountOptionEnabled() -> UIColor

    func shadowOpacity() -> Float
}

class ThemeController {

    struct Static {
        static let themes: [Theme] = [ThemeLight(), ThemeDark(), ThemeSolarizedLight(), ThemeSolarizedDark(), ThemeMonokai()]
        static var currentTheme: Theme = ThemeLight()
    }

    class var currentTheme: Theme { return Static.currentTheme }

    class func apply() {
        if let themeName = KeyClip.load("theme") as String? {
            for theme in Static.themes {
                if theme.name() == themeName {
                    apply(theme)
                    return
                }
            }
        }
        apply(currentTheme, refresh: false)
    }

    // swiftlint:disable:next function_body_length
    class func apply(_ theme: Theme, refresh: Bool = true) {

        Static.currentTheme = theme

        // for UIKit

        // Note: Adding "View controller-based status bar appearance" to info.plist and setting it to "NO"
        UIApplication.shared.statusBarStyle = theme.statusBarStyle()
        UITextView.appearance().textColor = theme.bodyTextColor()
        UITextView.appearance().backgroundColor = theme.mainBackgroundColor()
        UITextField.appearance().textColor = theme.bodyTextColor()
        UITextField.appearance().backgroundColor = theme.mainBackgroundColor()
        UITextField.appearance().layer.borderColor = theme.cellSeparatorColor().cgColor
        UITextField.appearance().tintColor = theme.bodyTextColor()
        UITableView.appearance().separatorColor = theme.cellSeparatorColor()
        UISegmentedControl.appearance().tintColor = theme.bodyTextColor()

        // for CustomView
        TextLable.appearance().textColor = theme.bodyTextColor()
        BackgroundTableView.appearance().backgroundColor = theme.mainBackgroundColor()
        BackgroundTableView.appearance().indicatorStyle = theme.scrollViewIndicatorStyle()
        BackgroundTableViewCell.appearance().backgroundColor = theme.mainBackgroundColor()
        BackgroundScrollView.appearance().backgroundColor = theme.mainBackgroundColor()
        BackgroundScrollView.appearance().indicatorStyle = theme.scrollViewIndicatorStyle()
        ImagePickerCollectionView.appearance().backgroundColor = theme.mainBackgroundColor()
        ImagePickerCollectionView.appearance().indicatorStyle = theme.scrollViewIndicatorStyle()
        BackgroundView.appearance().backgroundColor = theme.mainBackgroundColor()
        CurrentTabMaskView.appearance().backgroundColor = theme.menuTextColor()
        NavigationShadowView.appearance().backgroundColor = theme.menuBackgroundColor().withAlphaComponent(0.8)
        NavigationShadowView.appearance().layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        MenuView.appearance().backgroundColor = theme.menuBackgroundColor()
        MenuShadowView.appearance().layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        MenuButton.appearance().setTitleColor(theme.menuTextColor(), for: UIControlState())
        MenuButton.appearance().setTitleColor(theme.menuSelectedTextColor(), for: .selected)
        TabButton.appearance().setTitleColor(theme.menuTextColor(), for: UIControlState())
        TabButton.appearance().setTitleColor(theme.menuSelectedTextColor(), for: .selected)
        MenuLable.appearance().textColor = theme.menuTextColor()
        SideMenuShadowView.appearance().backgroundColor =  theme.sideMenuBackgroundColor()
        SideMenuSeparator.appearance().backgroundColor = theme.menuTextColor()
        UISwitch.appearance().tintColor = theme.switchTintColor()

        ShowMoreTweetBackgroundView.appearance().backgroundColor = theme.showMoreTweetBackgroundColor()
        ShowMoreTweetLabel.appearance().textColor = theme.showMoreTweetLabelTextColor()
        ShowMoreTweetIndicatorView.appearance().activityIndicatorViewStyle = theme.showMoreTweetIndicatorStyle()

        // for TwitterStatus
        DisplayNameLable.appearance().textColor = theme.displayNameTextColor()
        ScreenNameLable.appearance().textColor = theme.screenNameTextColor()
        ClientNameLable.appearance().textColor = theme.clientNameTextColor()
        RelativeDateLable.appearance().textColor = theme.relativeDateTextColor()
        AbsoluteDateLable.appearance().textColor = theme.absoluteDateTextColor()
        StatusLable.appearance().textColor = theme.bodyTextColor()

        ReplyButton.appearance().setTitleColor(theme.buttonNormal(), for: UIControlState())
        ReplyButton.appearance().setTitleColor(theme.buttonNormal(), for: .selected)
        RetweetButton.appearance().setTitleColor(theme.buttonNormal(), for: UIControlState())
        RetweetButton.appearance().setTitleColor(theme.retweetButtonSelected(), for: .selected)
        FavoritesButton.appearance().setTitleColor(theme.buttonNormal(), for: UIControlState())
        FavoritesButton.appearance().setTitleColor(theme.favoritesButtonSelected(), for: .selected)

        FollowButton.appearance().setTitleColor(theme.buttonNormal(), for: UIControlState())
        UnfollowButton.appearance().setTitleColor(theme.mainBackgroundColor(), for: UIControlState())

        if refresh {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            refreshAppearance(theme)
            CATransaction.commit()

            KeyClip.save("theme", string: theme.name())
        }
    }

    class func refreshAppearance(_ theme: Theme) {
        let windows = UIApplication.shared.windows as [UIWindow]
        for window in windows {
            refreshWindow(window, theme: theme)
        }
        if let rootView = windows.first?.subviews.first {
            rootView.backgroundColor = theme.mainBackgroundColor()
        }
        windows.first?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
    }

    class func refreshWindow(_ window: UIWindow, theme: Theme) {
        // NSLog("+ \(NSStringFromClass(window.dynamicType))")
        for subview in window.subviews as [UIView] {
            refreshView(subview, theme: theme)
        }
    }

    // swiftlint:disable cyclomatic_complexity
    // swiftlint:disable function_body_length
    class func refreshView(_ view: UIView, theme: Theme, indent: String = "  ") {
        // NSLog("\(indent)- \(NSStringFromClass(view.dynamicType))")
        for subview in view.subviews as [UIView] {
            refreshView(subview, theme: theme, indent: indent + "  ")
            switch subview {
            case let v as UISegmentedControl:
                v.tintColor = theme.bodyTextColor()
            case let v as BackgroundScrollView:
                v.indicatorStyle = theme.scrollViewIndicatorStyle()
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as BackgroundTableView:
                v.indicatorStyle = theme.scrollViewIndicatorStyle()
                v.backgroundColor = theme.mainBackgroundColor()
                v.separatorColor = theme.cellSeparatorColor()
            case let v as UITableView:
                v.indicatorStyle = theme.scrollViewIndicatorStyle()
                v.backgroundColor = theme.mainBackgroundColor()
                v.separatorColor = theme.cellSeparatorColor()
            case let v as StatusLable:
                v.setAttributes()
            case let v as UITextView:
                v.textColor = theme.bodyTextColor()
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as UITextField:
                v.textColor = theme.bodyTextColor()
                v.tintColor = theme.bodyTextColor()
                v.backgroundColor = theme.mainBackgroundColor()
                v.layer.borderColor = theme.cellSeparatorColor().cgColor
            case let v as BackgroundTableViewCell:
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as BackgroundView:
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as ImagePickerCollectionView:
                v.indicatorStyle = theme.scrollViewIndicatorStyle()
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as CurrentTabMaskView:
                v.backgroundColor = theme.menuTextColor()
            case let v as SideMenuSeparator:
                v.backgroundColor = theme.menuTextColor()
            case let v as SideMenuShadowView:
                v.backgroundColor = theme.sideMenuBackgroundColor()
                v.layer.shadowOpacity = theme.shadowOpacity()
            case let v as UISwitch:
                v.tintColor = theme.switchTintColor()
            case let v as MenuShadowView:
                v.backgroundColor = theme.menuBackgroundColor()
                v.layer.shadowOpacity = theme.shadowOpacity()
                // v.layer.setNeedsLayout()
            case let v as NavigationShadowView:
                v.backgroundColor = theme.menuBackgroundColor().withAlphaComponent(0.8)
                v.layer.shadowOpacity = theme.shadowOpacity()
            case let v as MenuView:
                v.backgroundColor = theme.menuBackgroundColor()
            case let v as ShowMoreTweetIndicatorView:
                v.activityIndicatorViewStyle = theme.showMoreTweetIndicatorStyle()
            case let v as ShowMoreTweetBackgroundView:
                v.backgroundColor = theme.showMoreTweetBackgroundColor()
            case let v as ShowMoreTweetLabel:
                v.textColor = theme.showMoreTweetLabelTextColor()
            case let v as TabButton:
                if v.streaming {
                    v.setTitleColor(theme.streamingConnected(), for: UIControlState())
                } else {
                    v.setTitleColor(theme.menuTextColor(), for: UIControlState())
                }
                v.setTitleColor(theme.menuSelectedTextColor(), for: .selected)
            case let v as MenuButton:
                v.setTitleColor(theme.menuTextColor(), for: UIControlState())
                v.setTitleColor(theme.menuSelectedTextColor(), for: .selected)
            case let v as TextLable:
                v.textColor = theme.titleTextColor()
            case let v as MenuLable:
                v.textColor = theme.menuTextColor()
            case let v as DisplayNameLable:
                v.textColor = theme.displayNameTextColor()
            case let v as ScreenNameLable:
                v.textColor = theme.screenNameTextColor()
            case let v as ClientNameLable:
                v.textColor = theme.clientNameTextColor()
            case let v as RelativeDateLable:
                v.textColor = theme.relativeDateTextColor()
            case let v as AbsoluteDateLable:
                v.textColor = theme.absoluteDateTextColor()
            case let v as ReplyButton:
                v.setTitleColor(theme.buttonNormal(), for: UIControlState())
                v.setTitleColor(theme.buttonNormal(), for: .selected)
            case let v as RetweetButton:
                v.setTitleColor(theme.buttonNormal(), for: UIControlState())
                v.setTitleColor(theme.retweetButtonSelected(), for: .selected)
            case let v as FavoritesButton:
                v.setTitleColor(theme.buttonNormal(), for: UIControlState())
                v.setTitleColor(theme.favoritesButtonSelected(), for: .selected)
            case let v as FollowButton:
                v.setTitleColor(theme.buttonNormal(), for: UIControlState())
            case let v as UnfollowButton:
                v.setTitleColor(theme.mainBackgroundColor(), for: UIControlState())
            case let v as StreamingButton:
                v.normalColor = theme.bodyTextColor()
                v.connectedColor = theme.streamingConnected()
                v.errorColor = theme.streamingError()
                v.setTitleColor()
            case let v as QuotedStatusContainerView:
                v.layer.borderColor = theme.cellSeparatorColor().cgColor
            case let v as UIActivityIndicatorView:
                v.activityIndicatorViewStyle = theme.activityIndicatorStyle()
            default:
                break
            }
        }
    }
    // swiftlint:enable cyclomatic_complexity
    // swiftlint:enable function_body_length

    // viewWillAppear of various ViewController is executed.
    // very heavy.
    class func refreshAppearanceSuperSlow() {
        let windows = UIApplication.shared.windows as [UIWindow]
        for window in windows {
            let subviews = window.subviews as [UIView]
            for v in subviews {
                v.removeFromSuperview()
                window.addSubview(v)
            }
        }
    }
}

private extension UIColor {
    var imageValue: UIImage {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        view.backgroundColor = self
        view.alpha = 1
        UIGraphicsBeginImageContext(view.frame.size)
        let context = UIGraphicsGetCurrentContext()!
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image!
    }
}
