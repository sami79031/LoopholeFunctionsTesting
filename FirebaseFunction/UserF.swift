//
//  UserF.swift
//  FirebaseFunction
//
//  Created by Sami Ali on 11/6/17.
//  Copyright © 2017 Sami Ali. All rights reserved.
//

import UIKit
import FirebaseDatabase

let kUSER = "USER"
let PUSH_ID = "pushId"

let firebase = Database.database().reference()

class UserF: NSObject {
    var userName: String?
    var pushId: String?
    
    private static var privateShared : UserF?
    
    class func shared() -> UserF {
        guard let uwShared = privateShared else {
            privateShared = UserF()
            return privateShared!
        }
        return uwShared
    }
    
    private override init() {
        print("init singleton")
    }
    
    deinit {
        print("deinit singleton")
    }
    
    class func destroy() {
        privateShared = nil
    }
    
    func updateUserPushId( _ pushId: String, completion: (() -> Swift.Void)? = nil){
        guard let userName = userName else {
            if let comp = completion{
                comp()
            }
            return
        }
        firebase.child(kUSER).child(userName).setValue([PUSH_ID : pushId]) { (err, ref) in
            if let comp = completion{
                comp()
            }
        }
            
        
    }
    
    func createUser( _ pushId: String){
        guard let userName = userName else {
            return
        }
        firebase.child(kUSER).child(userName).updateChildValues([PUSH_ID : pushId])
    }
    
    func checkIfUserAlreadyExists(currentUserName: String, withBlock: @escaping (_ doesUserEixst: Bool) -> Void){
        firebase.child(kUSER).queryOrderedByKey().queryEqual(toValue: currentUserName).observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                withBlock(true)
            }else{
                withBlock(false)
            }
        }){ (error) in
            print(error.localizedDescription)
        }
    }
}
