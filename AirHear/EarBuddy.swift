//
//  EarBuddy.swift
//  AirHear
//
//  Created by Todd on 5/30/19.
//  Copyright © 2019 Todd Bruss. All rights reserved.
//

import Foundation
import AudioKit


class EarBuddy {
    
    var AirPodsDetected = false
    var AirPodsGeniune  = false
    
    var AirPodsName     = "AirPods"
    var AirPodsFakeName = "Airpods"
    
    var AirPodsGeniuneMsg        = "No errors."
    var AirPodsUnpluggedMsg      = "Both AirPods are unplugged."
    var badMessage               = "Apple AirPods not detected."
    var AirPodsNotGeniuneMsg     = "BluetoothHFP device name must contain AirPods."
    var unknownMessage           = "Unknown error has occurred."
    
    var mic             = AKMicrophone()
    var boost           = AKBooster()
    var limit           = AKPeakLimiter()
    
    enum AirPodStatus : CaseIterable {
        case AirPodsNotGeniune
        case AirPodsNotDetected
        case AirPodsGeniune
        case AirPodsUnplugged
        case UnknownError
    }
    
    //determines if the AirPod is Genuine and Connected
    func AirPod(isGenuine: AirPodStatus) -> Bool {
        
        switch isGenuine {
        case .AirPodsGeniune:
            return (AirPodsDetected && AirPodsGeniune)
        case .AirPodsUnplugged:
            return (!AKSettings.headPhonesPlugged)
        case .AirPodsNotDetected:
            return (!AirPodsDetected)
        case .AirPodsNotGeniune:
            return (AirPodsDetected && !AirPodsGeniune)
        case .UnknownError:
            return (false)
        }
    }
    
    //return error messages of the AirPod's status
    func AirPort(Result: AirPodStatus) -> (success: Bool, error: String) {
        
        switch Result {
        case .AirPodsGeniune:
            return (success: true, error: AirPodsGeniuneMsg)
        case .AirPodsUnplugged:
            return (success: false, error: AirPodsUnpluggedMsg)
        case .AirPodsNotDetected:
            return (success: false, error: badMessage)
        case .AirPodsNotGeniune:
            return (success: false, error: AirPodsNotGeniuneMsg)
        case .UnknownError:
            return (success: false, error: unknownMessage)
        }
    }
}

class Session : EarBuddy  {
    
    let audioSession = AVAudioSession.sharedInstance()
    
    func getInputs()  {
        
        AirPodsDetected = false
        AirPodsGeniune = false
        
        if let inputs = audioSession.availableInputs {
            for i in inputs {
                if i.portType == .bluetoothHFP {
                    AirPodsDetected = true
                    
                    if i.portName.contains(AirPodsName) {
                        AirPodsGeniune = true
                    } else if i.portName == AirPodsFakeName {
                        AirPodsGeniune = false
                    }
                    break
                }
            }
        }
    }
    
    func startSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode:.voiceChat, options:.allowBluetooth)
            try audioSession.setActive(true)
            
            if audioSession.isInputGainSettable {
                try audioSession.setInputGain(0)
            }
            
            try audioSession.setPreferredIOBufferDuration(0.0001)
            try audioSession.setPreferredInput(audioSession.availableInputs?.first)
            try audioSession.setPreferredSampleRate(22_050)
            try audioSession.setPreferredOutputNumberOfChannels(1)
            try audioSession.setPreferredInputNumberOfChannels(1)
            
            
            getInputs()
            
        } catch {
            print(error)
        }
    }
    
    
    func fireStarter(status: AirPodStatus) -> (success: Bool, error: String) {
        
        switch status {
            
        case .AirPodsGeniune:
            
            do {
                try AudioKit.start()
                if AirPod(isGenuine: .AirPodsUnplugged) {
                    try AudioKit.stop()
                    return AirPort(Result: .AirPodsUnplugged)
                }
                
                return AirPort(Result: .AirPodsGeniune)
                
                
            } catch {
                //We don't know what the error is, so let's display it
                return (success: false, error: error.localizedDescription)
            }
            
        case .AirPodsUnplugged:
            return AirPort(Result: .AirPodsUnplugged)
        case .AirPodsNotDetected:
            return AirPort(Result: .AirPodsNotDetected)
        case .AirPodsNotGeniune:
            return AirPort(Result: .AirPodsNotGeniune)
        case .UnknownError:
            return AirPort(Result: .UnknownError)
        }
    }
    
    
    
    /// Determine of Start is okay
    /// If not, don't start
    /// Does our dirty work for us.
    func start() -> (success: Bool, error: String) {
        for type in AirPodStatus.allCases {
            if ( AirPod(isGenuine: type) ) {
                return fireStarter(status: type)
            }
        }
        
        return fireStarter(status: .UnknownError)
    }
    
    //Stop requires no checks
    func stop() {
        do {
            
            try AudioKit.stop()
            
        } catch {
            print(error)
        }
    }
    
    func settings(
        gain           : Double = 1.0,
        preGain        : Double = 0,
        attackDuration : Double = 0.005,
        decayDuration  : Double = 0.010,
        rampDuration   : Double = 0.015,
        volume         : Double = 0.5
        ) {
        
        boost.gain = gain
        boost.rampDuration = rampDuration
        
        limit.preGain = preGain
        limit.attackDuration = attackDuration
        limit.decayDuration = decayDuration
        limit.dryWetMix = 1.0
        if let mike = mic {
            mike.volume = volume
            mike >>> boost >>> limit
            AudioKit.output = limit
        }
        AKSettings.bufferLength = .medium
        AKSettings.useBluetooth = true
        AKSettings.bluetoothOptions = .allowBluetoothA2DP
        
    }
    
    func internalMic () {
        AKSettings.bluetoothOptions = .allowBluetoothA2DP
        
        if AKSettings.headPhonesPlugged {
            _ = start()
        }
        
    }
    
    func externalMic () {
        AKSettings.bluetoothOptions = .allowBluetooth
        
        if AKSettings.headPhonesPlugged {
            _ = start()
        }
    }
    
    
    func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: audioSession)
    }
    
    @objc func handleRouteChange(_ notification: Notification) {
        guard let routeChange = AVAudioSession.RouteChangeReason(rawValue:notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as! UInt) else {
            return
        }
        switch routeChange {
        case .newDeviceAvailable:
            if (AKSettings.headPhonesPlugged) {
                _ = start()
            }
        // Handle new device available.
        case .oldDeviceUnavailable:
            if (!AKSettings.headPhonesPlugged) {
                stop()
            }
        // Handle old device removed.
        default:
            return
        }
    }
}

