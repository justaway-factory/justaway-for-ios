//
//  AlertController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/17/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class AlertController {
    class func showViewController(alert: UIAlertController) {
        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            vc.presentViewController(alert, animated: true, completion: nil)
        }
    }
}