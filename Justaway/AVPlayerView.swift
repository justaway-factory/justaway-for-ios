//
//  AVPlayerView.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/22/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import AVFoundation

class AVPlayerView: UIView {
    
    var player: AVPlayer? {
        get {
            let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
            return layer.player
        }
        set(newValue) {
            let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
            layer.player = newValue
        }
    }
    
    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
    
    func setVideoFillMode(mode: String) {
        let layer: AVPlayerLayer = self.layer as! AVPlayerLayer
        layer.videoGravity = mode
    }
}