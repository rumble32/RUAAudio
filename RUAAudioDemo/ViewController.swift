//
//  ViewController.swift
//  RUAAudioDemo
//
//  Created by mol on 16/7/4.
//  Copyright © 2016年 rua. All rights reserved.
//

import UIKit
import AVFoundation
import RUAAudio

class ViewController: UIViewController {

    var sampleRate = 44100.0;
    var graph: RUAGraph?
    
    deinit {
        
        NotificationCenter.default().removeObserver(self)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        setupSession()
        
        graph = RUAGraph()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    func setupSession() -> Void {
        
        let mySession = AVAudioSession.sharedInstance();
        
        do {
            try mySession.setCategory(AVAudioSessionCategoryPlayback)
        } catch let error as NSError  {
            print("AVAudioSession setCategory error: \(error)")
        }
        
        do {
            try mySession.setPreferredSampleRate(sampleRate)
        } catch let error as NSError {
            print("AVAudioSession setPreferredSampleRate error: \(error)")
        }
        
        do {
            try mySession.setActive(true)
        } catch let error as NSError {
            print("AVAudioSession setActive error: \(error)")
        }
        
        // Obtain the actual hardware sample rate
        sampleRate = mySession.sampleRate;
        
        NotificationCenter.default().addObserver(self, selector: #selector(self.audioSessionDidInterruption(notif:)), name: NSNotification.Name.AVAudioSessionInterruption, object: AVAudioSession.sharedInstance())
    }
    
    func audioSessionDidInterruption(notif: Notification) -> Void {
        
        
    }
}

