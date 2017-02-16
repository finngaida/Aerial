//
//  ViewController.swift
//  ScreenSaver
//
//  Created by Finn Gaida on 16/02/2017.
//  Copyright © 2017 Finn Gaida. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {

    var playerLayer: AVPlayerLayer!
    var players: [AVPlayer] = [AVPlayer]()
    
    var player: AVPlayer?

    
    // MARK: - Init / Setup
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    /*deinit {
//        debugLog("deinit AerialView")
        NotificationCenter.default.removeObserver(self)
        
        // set player item to nil if not preview player
        if player != AerialView.previewPlayer {
            player?.rate = 0
            player?.replaceCurrentItem(with: nil)
        }
        
        guard let player = self.player else {
            return
        }
        
        // Remove from player index
        
        let indexMaybe = AerialView.players.index(of: player)
        
        guard let index = indexMaybe else {
            return
        }
        
        AerialView.players.remove(at: index)
    }*/
    
    func setupPlayerLayer(withPlayer player: AVPlayer) {
        self.view.layer.backgroundColor = UIColor.black.cgColor
        self.view.layer.needsDisplayOnBoundsChange = true
        self.view.layer.frame = self.view.frame
        //        layer.backgroundColor = NSColor.greenColor().CGColor
        
//        debugLog("setting up player layer with frame: \(self.bounds) / \(self.frame)")
        
        playerLayer = AVPlayerLayer(player: player)
        if #available(OSX 10.10, *) {
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        }
        playerLayer.frame = self.view.layer.bounds
        self.view.layer.addSublayer(playerLayer)
    }
    
    func setup() {
        var localPlayer: AVPlayer?
        
        if localPlayer == nil {
            localPlayer = AVPlayer()
        }
        
        guard let player = localPlayer else {
            NSLog("Aerial Error: Couldn't create AVPlayer!")
            return
        }
        
        self.player = player
        
            // add to player list
            players.append(player)
        
        setupPlayerLayer(withPlayer: player)
        
        ManifestLoader.instance.addCallback { videos in
            self.playNextVideo()
        }
    }
    
    // MARK: - AVPlayerItem Notifications
    
    func playerItemFailedtoPlayToEnd(_ aNotification: Notification) {
        NSLog("AVPlayerItemFailedToPlayToEndTimeNotification \(aNotification)")
        
        playNextVideo()
    }
    
    func playerItemNewErrorLogEntryNotification(_ aNotification: Notification) {
        NSLog("AVPlayerItemNewErrorLogEntryNotification \(aNotification)")
    }
    
    func playerItemPlaybackStalledNotification(_ aNotification: Notification) {
        NSLog("AVPlayerItemPlaybackStalledNotification \(aNotification)")
    }
    
    func playerItemDidReachEnd(_ aNotification: Notification) {
//        debugLog("played did reach end")
//        debugLog("notification: \(aNotification)")
        playNextVideo()
        
//        debugLog("playing next video for player \(player)")
    }
    
    // MARK: - Playing Videos
    
    func playNextVideo() {
        let notificationCenter = NotificationCenter.default
        
        // remove old entries
        notificationCenter.removeObserver(self)
        
        let player = AVPlayer()
        // play another video
        self.player = player
        self.playerLayer.player = self.player
        
        
        let randomVideo = ManifestLoader.instance.randomVideo()
        
        guard let video = randomVideo else {
            NSLog("Aerial: Error grabbing random video!")
            return
        }
        let videoURL = video.url
        
        let asset = CachedOrCachingAsset(videoURL)
        //        let asset = AVAsset(URL: videoURL)
        
        let item = AVPlayerItem(asset: asset)
        
        player.replaceCurrentItem(with: item)
        
//        debugLog("playing video: \(video.url)")
        if player.rate == 0 {
            player.play()
        }
        
        guard let currentItem = player.currentItem else {
            NSLog("Aerial Error: No current item!")
            return
        }
        
//        debugLog("observing current item \(currentItem)")
        notificationCenter.addObserver(self,
                                       selector: #selector(playerItemDidReachEnd(_:)),
                                       name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                       object: currentItem)
        notificationCenter.addObserver(self,
                                       selector: #selector(playerItemNewErrorLogEntryNotification(_:)),
                                       name: NSNotification.Name.AVPlayerItemNewErrorLogEntry,
                                       object: currentItem)
        notificationCenter.addObserver(self,
                                       selector: #selector(playerItemFailedtoPlayToEnd(_:)),
                                       name: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime,
                                       object: currentItem)
        notificationCenter.addObserver(self,
                                       selector: #selector(playerItemPlaybackStalledNotification(_:)),
                                       name: NSNotification.Name.AVPlayerItemPlaybackStalled,
                                       object: currentItem)
        player.actionAtItemEnd = AVPlayerActionAtItemEnd.none
    }

}

