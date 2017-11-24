//
//  Gestures.swift
//  MoveSDK
//
//  Created by Canozan Kusseven on 21.11.2017.
//  Copyright © 2017 Canozan Kusseven. All rights reserved.
//

import Foundation
import UIKit
import SystemConfiguration
import Foundation
import AudioToolbox
import AVFoundation
import EventKit
import UserNotifications

open class MoveSDKGestures: NSObject {
    
    
    // Vibrate Device
    
    
    func vibrate(){
        
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    
    // Set Brightness Level (Double)
    
    
     func setBrightness(brighnessLevel:Double) {
        
        UIScreen.main.brightness = CGFloat(brighnessLevel)
        
        
    }
    
    
    // Get Brightness
    
     func getBrightness() -> String {
        
        var state = String()
        let brightness = Double(UIScreen.main.brightness)
        
        if brightness >= 0.8 {
            state = "high"
            
        } else if brightness < 0.8 && brightness >= 0.5 {
            state = "medium"
            
        } else if brightness < 0.5 && brightness >= 0.2 {
            state = "low"
            
        } else if brightness < 0.2 {
            state = "ultra low"
        }
        
        return state
        
    }
    
    
    // Turn on Flash
    
     func turnOnFlash() {
        
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        
        if (device?.hasTorch)! {
            
            
            do {
                try device?.lockForConfiguration()
                device?.torchMode = .on
                device?.unlockForConfiguration()
                
            } catch {
                
                print("Torch could not be used")
                
            }
            
        } else {
            print("Torch is not available")
        }
        
    }
    
    
    
    
    // Turn off Flash
    
     func turnOffFlash() {
        
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        
        if (device?.hasTorch)! {
            
            do {
                try device?.lockForConfiguration()
                device?.torchMode = .off
                device?.unlockForConfiguration()
                
            } catch {
                
                print("Torch could not be used")
                
            }
            
        } else {
            print("Torch is not available")
        }
        
    }
    
    
    
    // Create calendar event
    
     func createEvent(title: String, notes: String, startDate: String, startTime: String, endDate: String, endTime:String) {
        let eventStore : EKEventStore = EKEventStore()
        
        //Access permission
        eventStore.requestAccess(to: EKEntityType.event) { (granted,error) in
            
            if (granted) &&  (error == nil) {
                print("permission is granted")
                
                let event:EKEvent = EKEvent(eventStore: eventStore)
                event.title = title
                
                let userCalendar = Calendar.current
                let dateMakerFormatter = DateFormatter()
                dateMakerFormatter.calendar = userCalendar
                dateMakerFormatter.dateFormat = "dd/MM/yyyy hh:mm"
                let sDate = dateMakerFormatter.date(from: startDate + " " + startTime)!
                let eDate = dateMakerFormatter.date(from: endDate + " " + endTime)!
                
                event.startDate = sDate
                event.endDate = eDate
                event.notes = notes
                event.calendar = eventStore.defaultCalendarForNewEvents
                
                event.addAlarm(EKAlarm.init(relativeOffset: -300.0))
                
                
                    do {
                        try eventStore.save(event, span: .thisEvent)
                    } catch let specError as NSError {
                        print("A specific error occurred: \(specError)")
                    } catch {
                        print("An error occurred")
                    }
                    
                
                print("Event saved")
                
            } else {
                print("need permission to create a event")
            }
        }
        
    }
    
    
    
    // Battery Informatio -> dictionary
    
     func getBatteryInformation() -> Dictionary<String , Any> {
        
        var batteryState = String()
        var batteryStatus = String()
        var batteryMode = String()
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        let batteryS = UIDevice.current.batteryLevel
        
        if batteryS > 0.8 && batteryS < 0.99 {
            
            batteryStatus = "charged"
            
        } else if batteryS < 0.8 && batteryS >= 0.5 {
            
            
            batteryStatus = "half full"
            
        } else if batteryS < 0.5 && batteryS >= 0.2 {
            
            batteryStatus = "low"
            
            
        } else if batteryS < 0.2 {
            
            batteryStatus = "battery critical"
            
        } else if batteryS == 1.0 {
            
            
            batteryStatus = "full"
            
        }
        
        
        if UIDevice.current.batteryState == .charging {
            
            batteryState = "charging"
            
        }  else if UIDevice.current.batteryState == .unplugged {
            
            batteryState = "runs on battery"
            
        }
        
        
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            batteryMode = "low power consumption mode"
            
        } else {
            batteryMode = "normal"
        }
        
        
        
        
        let information = ["batteryStatus" : batteryStatus,
                           "batteryState" : batteryState,
                           "batteryMode" : batteryMode
            ] as [String : Any]
        
        return information
        
    }
    
    
    
    
    // get device name
    
    
     func getDeviceInformation() -> Dictionary<String , Any> {
        
        let deviceName = UIDevice.current.name
        let deviceModel = UIDevice.current.localizedModel
        let systemV = UIDevice.current.systemVersion
        
        let information = ["deviceName" : deviceName,
                           "deviceModel" : deviceModel,
                           "systemVersiın" : systemV
            ] as [String : Any]
        
        return information
        
    }
    
    
    
    // earphone status
    
    
     func getEarPhoneStatus() -> String {
        var isEarPhoneOn: Bool = false
        var earphoneStatus = String()
        let route: AVAudioSessionRouteDescription = AVAudioSession.sharedInstance().currentRoute
        for desc: AVAudioSessionPortDescription in route.outputs {
            if (desc.portType == AVAudioSessionPortHeadphones) {
                isEarPhoneOn = true
            }
        }
        
        if isEarPhoneOn {
            
            earphoneStatus = "plugged"
            
        } else {
            
            earphoneStatus = "unplugged"
        }
        
        return earphoneStatus
    }
    
    
    
    // Get volumelevel
    
    func getVolumeLevel() -> String {
        var volume: Float
        var volumeLevel = String()
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        }
        catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
        catch _ {
        }
        volume = AVAudioSession.sharedInstance().outputVolume
        
        if volume > 0.8 {
            
            volumeLevel = "high volume"
            
            
        } else if volume < 0.8 && volume >= 0.5 {
            
            
            volumeLevel = "mid volume"
            
            
        } else if volume > 0.5 && volume >= 0.2 {
            
            volumeLevel = "low volume"
            
        } else if volume < 0.2 {
            
            volumeLevel = "ultra low volume"
            
        }
        
        return volumeLevel
    }
    
    
    
    // get available disk size
    
    func getDiskAvailable() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let dictionary = try? FileManager.default.attributesOfFileSystem(forPath: paths.last!) {
            if let freeSize = dictionary[FileAttributeKey.systemFreeSize] as? NSNumber {
                
                let FF = freeSize.int64Value / 1024 / 1024
                var can = String()
                
                if  FF > 100000 {
                    
                    can = "very high"
                    
                } else if FF < 100000 && FF >= 80000 {
                    
                    can = "high"
                    
                    
                } else if FF < 80000 && FF >= 50000 {
                    
                    
                    can = "medium"
                    
                    
                }
                
                
                return can
                
                
            } else{
            print("Error Obtaining System Memory Info:")
        }
            
            
    }
    
        return ""
    
    }
    
}
