//
//  ThemeSolarizedDark.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/15/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ThemeSolarizedDark: Theme {

    func name() -> String { return "SolarizedDark" }

    func statusBarStyle() -> UIStatusBarStyle { return .lightContent }
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle { return .white }
    func showMoreTweetIndicatorStyle() -> UIActivityIndicatorViewStyle { return .gray }
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle { return .white }

    func mainBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes03 }
    func mainHighlightBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes02 }
    func titleTextColor() -> UIColor { return ThemeColor.Solarized.baes1 }
    func bodyTextColor() -> UIColor { return ThemeColor.Solarized.baes1 }
    func cellSeparatorColor() -> UIColor { return ThemeColor.Solarized.baes1 }

    func sideMenuBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes03 }
    func switchTintColor() -> UIColor { return ThemeColor.Solarized.baes1 }

    func displayNameTextColor() -> UIColor { return ThemeColor.Solarized.yellow }
    func screenNameTextColor() -> UIColor { return ThemeColor.Solarized.red }
    func relativeDateTextColor() -> UIColor { return ThemeColor.Solarized.magenta }
    func absoluteDateTextColor() -> UIColor { return ThemeColor.Solarized.blue }
    func clientNameTextColor() -> UIColor { return ThemeColor.Solarized.cyan }

    func menuBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes02 }
    func menuTextColor() -> UIColor { return ThemeColor.Solarized.baes1 }
    func menuHighlightedTextColor() -> UIColor { return UIColor(red: 0.58, green: 0.63, blue: 0.63, alpha: 0.5) }
    func menuSelectedTextColor() -> UIColor { return ThemeColor.Solarized.blue }
    func menuDisabledTextColor() -> UIColor { return ThemeColor.Solarized.baes01 }

    func showMoreTweetBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes1 }
    func showMoreTweetLabelTextColor() -> UIColor { return ThemeColor.Solarized.baes03 }

    func buttonNormal() -> UIColor { return ThemeColor.Solarized.baes1 }
    func retweetButtonSelected() -> UIColor { return ThemeColor.Solarized.green }
    func favoritesButtonSelected() -> UIColor { return ThemeColor.Solarized.red }
    func followButtonSelected() -> UIColor { return ThemeColor.Solarized.blue }
    func streamingConnected() -> UIColor { return ThemeColor.Solarized.green }
    func streamingError() -> UIColor { return ThemeColor.Solarized.red }

    func accountOptionEnabled() -> UIColor { return ThemeColor.Solarized.blue }

    func shadowOpacity() -> Float { return 0.5 }
}
