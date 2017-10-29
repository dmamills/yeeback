//
//  YeeViewController.swift
//  richoniphone
//
//  Created by Daniel Mills on 2017-02-26.
//  Copyright © 2017 Daniel Mills. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class YeeViewController : UIViewController, AVAudioRecorderDelegate {
    
    var audioEngine : AVAudioEngine!
    var audioPlayerNode : AVAudioPlayerNode!
    var yeeAudioFile: AVAudioFile!
    var recordedAudioFile : AVAudioFile!
    var recordingSession : AVAudioSession!
    var audioRecorder : AVAudioRecorder!
    
    var isRecording : Bool!
    var pitch : Float = 0.0
    var rate : Float = 1.0
    
    @IBOutlet weak var recordBtn : UIButton!
    
    let PLAYBACK_SETTINGS = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    override func viewDidLoad() {
         super.viewDidLoad()
        
        isRecording = false
        
        do {
            recordingSession = AVAudioSession.sharedInstance()
            
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord,  with:AVAudioSessionCategoryOptions.defaultToSpeaker)
            try recordingSession.setActive(true)
            
            let path = Bundle.main.path(forResource: "yee.mp3", ofType: nil)!
            let url = URL(fileURLWithPath: path)
            audioEngine = AVAudioEngine();
            yeeAudioFile = try AVAudioFile(forReading: url)
            
        } catch {
            print("error")
        }
    }
    
    @IBAction func onRecordTouch(_ sender: UIButton) {
        
        if let btn = recordBtn {
            if isRecording == true {
                DispatchQueue.main.async {
                    btn.setImage(UIImage(named:"record-btn"), for: UIControlState.normal)
                }
                
                pauseRecording()
                isRecording = false
            } else {
                DispatchQueue.main.async {
                    btn.setImage(UIImage(named:"recording-btn"), for: UIControlState.normal)
                }
                record()
                isRecording = true
            }
        }
    }
    
   
    
    @IBAction func onButtonPressed(_ sender: UIButton) {
        //print("sender: \(sender.title(for: .normal))")
        
        var playbackFile = recordedAudioFile ?? yeeAudioFile
        
        if let title = sender.title(for: .normal) {
            
            if title == "Slow" {
                rate = Float(0.5)
                pitch = Float(0.0)
            }
            
            if title == "Very Slow" {
                rate = Float(0.25)
                pitch = Float(0.0)
                
            }
            
            if title == "Normal" {
                rate = Float(1)
                pitch = Float(0.0)
            }
            
            if title == "Squirrel" {
                rate = Float(1.5)
                pitch = Float(600)
            }

            if title == "   Very Squirrel" {
                rate = Float(1.5)
                pitch = Float(1200)
            }
            
            if title == "2x" {
                rate = Float(2)
                pitch = Float(0)
            }
            
            if title == "Squeel" {
                rate = Float(1)
                pitch = Float(1600)
            }
            
            if title == "Deep" {
                rate = Float(1)
                pitch = Float(-600)

            }
        }
        
        playAudioFile(playbackFile!)
    }
    
    
    func getUrlToRecordedFile(reversed : Bool = false) -> URL {
        
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        var recordedFilePath = ""
        if(reversed == false) {
            recordedFilePath = documentsDirectory +  "/recorded.mp4"
        } else {
            recordedFilePath = documentsDirectory + "/recorded-reverse.mp4"
        }
        
        return URL(fileURLWithPath: recordedFilePath)
    }
    
    func record() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            
            let url = getUrlToRecordedFile()
            
            // 4. create the audio recording, and assign ourselves as the delegate
            audioRecorder = try AVAudioRecorder(url: url, settings: PLAYBACK_SETTINGS)
            audioRecorder.prepareToRecord()
            audioRecorder.delegate = self
            
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord,  with:AVAudioSessionCategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true)
            
            audioRecorder.record()
        }
        catch let error {
            print(error)
        }
    }
    
    
    func pauseRecording() {
        
        if audioRecorder!.isRecording {
            print("recording. stopping.")
            audioRecorder?.stop();
            
            do {
                recordedAudioFile = try AVAudioFile(forReading: getUrlToRecordedFile())
            } catch {
                print("couldnt open file")
            }
        } else {
            print("not recording.")
        }
    }
    
    
    func createEffect(_ rate: Float, pitch: Float) -> AVAudioUnitTimePitch {
        let changePitchEffect = AVAudioUnitTimePitch()
        changePitchEffect.pitch = pitch
        changePitchEffect.rate = rate
        
        return changePitchEffect
    }
    

    func playAudioFile(_ audioFile: AVAudioFile) {
        
        //clear all playing, clear engine
        audioEngine.stop()
        audioEngine.reset()
        
        //attach a node to our engine
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        //set the effect and attach to engine
        let audioEffect = createEffect(rate, pitch: pitch)
        audioEngine.attach(audioEffect)
        
        //connect player to effect
        audioEngine.connect(audioPlayerNode, to: audioEffect, format: nil)
        
        //connect effect to output (speakers)
        audioEngine.connect(audioEffect, to: audioEngine.outputNode, format: nil)
        
        //schedule the playing of audio file
        audioPlayerNode.scheduleFile(audioFile, at: nil, completionHandler: {
            //TODO: add delay based on rate
            DispatchQueue.main.async( execute: {
                print("done playing!")
            })
        })
        
        //restart engine and play sound
        try! audioEngine.start()
        audioPlayerNode.play()
        
    }
    
}
