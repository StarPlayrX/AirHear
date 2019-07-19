//
//  ViewController.swift
//  AirHear
//
//  Created by Todd on 5/28/19.
//  Copyright © 2019 Todd Bruss. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    let session = Session()
    
    @IBAction func start(_ sender: Any) {
        let (success,message) = session.start()
        //session.start()
        if !success {
            self.showAlert(title: "Error", message: message, action: "OK")
        }
    }
    
    @IBAction func stop(_ sender: Any) {
         session.stop()
    }
    
    @IBOutlet weak var volumeValue: UISlider!
    @IBOutlet weak var dBValue: UISlider!
    @IBOutlet weak var preGainValue: UISlider!

    @IBAction func volume(_ sender: UISlider) {
        let volVal = Double(sender.value)
        session.mic?.volume = volVal
    }
    
    @IBAction func dB(_ sender: UISlider) {
        let g = Double(sender.value)
        session.boost.gain = g
    }

    @IBAction func preGainAction(_ sender: UISlider) {
        let preGain = Double(sender.value)
        session.limit.preGain = preGain
    }
    
    @IBOutlet weak var micSegmentValue: UISegmentedControl!
    @IBAction func micSegment(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
               case 0:
            session.internalMic()
        case 1:
            session.externalMic()
        default:
            break
        }  //Switch
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        session.startSession()
        session.settings()
        session.setupNotifications()
    }
    
    func complete() -> Void {
        session.startSession()
        sleep(1)
    }
    //Show Alert
    func showAlert(title: String, message:String, action:String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: action, style: .default, handler: { action in
            switch action.style {
            case .default:
                print("default")
            case .cancel:
                print("cancel")
            case .destructive:
                print("destructive")
            @unknown default:
                print("error.")
            }}))
        self.present(alert, animated: true, completion: complete )
    }
}
