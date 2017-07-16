//
//  ViewController.swift
//  DPBExample
//
//  Created by VAndrJ on 7/16/17.
//  Copyright © 2017 VAndrJ. All rights reserved.
//

import UIKit
import DownloadingProgressButton

class ViewController: UIViewController, DownloadingProgressButtonDelegate {
    func stateWasChanged(to newState: DownloadStates, sender: DownloadingProgressButton) {
        switch newState {
        case .none:
            print(".none: interrupt")
        case .pending:
            print(".pending: start downloading here")
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.5, execute: {
                self.isCancelled = false
                sender.downloadingStarted()
                self.addProgress(for: sender)
            })
        case .done:
            print(".done: Done downloading. All animations ended")
        default:
            break
        }
    }
    
    func openClick(sender: DownloadingProgressButton) {
        print("Open click")
    }
    
    func cancelDownloading(sender: DownloadingProgressButton) {
        print("Cancel downloading")
        isCancelled = true
        progress = 0
        sender.downloadingCancelled()
    }
    
    var isCancelled = false
    var progress: CGFloat = 0
    @IBOutlet weak var downloadingProgressButton: DownloadingProgressButton! {
        didSet {
            downloadingProgressButton.delegate = self
        }
    }
    
    func addProgress(for sender: DownloadingProgressButton) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            if !self.isCancelled {
                self.progress += CGFloat(20) / 100
                sender.downloadingProgressChanged(to: self.progress)
                if self.progress >= 1 {
                    self.progress = 0
                } else {
                    self.addProgress(for: sender)
                }
            }
        }
    }

    @IBAction func enabled(_ sender: UIButton) {
        downloadingProgressButton.isEnabled = !downloadingProgressButton.isEnabled
    }
    
    @IBAction func reset(_ sender: UIButton) {
        downloadingProgressButton.downloadingReset()
    }
    
    @IBAction func startDownloading(_ sender: UIButton) {
        downloadingProgressButton.startProgrammatically()
    }
    
    @IBAction func setDownloaded(_ sender: UIButton) {
        downloadingProgressButton.downloadingSet()
    }
}

