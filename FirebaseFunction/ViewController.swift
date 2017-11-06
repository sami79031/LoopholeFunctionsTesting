//
//  ViewController.swift
//  FirebaseFunction
//
//  Created by Sami Ali on 11/3/17.
//  Copyright © 2017 Sami Ali. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Firebase

class ViewController: UIViewController {
    @IBOutlet weak var userNameHolder: UILabel!
    
    @IBOutlet weak var currentlyCheckedIn: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidLayoutSubviews() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.9) {
            self.userNameHolder.text = UserF.shared().userName ?? "NaN"
            self.observeIfCurrentlyCheckedIn()
        }
    }
    
    
    @IBAction func logOut(_ sender: UIButton) {
        UserF.shared().updateUserPushId("") {
            UserDefaults.standard.removeObject(forKey: "kUSER_NAME")
            UserF.destroy()
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func observeIfCurrentlyCheckedIn(){
        firebase.child("CheckedInVenue").child(UserF.shared().userName!).observe(.value) { (snapshot) in
            if snapshot.exists(){
                let dict = snapshot.value as! NSDictionary
                if let venueName = dict["venueName"] as? String{
                    self.currentlyCheckedIn.text = venueName
                }
            }else{
                self.currentlyCheckedIn.text = "Not checked in yet!"
            }
        }
    }
    
    
}

extension Date {
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds / 1000))
    }
}
