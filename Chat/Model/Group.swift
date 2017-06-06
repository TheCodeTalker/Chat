//
//  Group.swift
//  Chat
//
//  Created by Chitaranjan Sahu on 06/06/17.
//  Copyright © 2017 xelpmoc.in. All rights reserved.
//

import UIKit
import Firebase

class Group: NSObject {
    
    let gName: String
    let gId: String?
    let gAdmin : String
    let gMember : [String]
    let gSendTo : String
    
    init(gName:String,gId: String,gAdmin : String,gMember : [String],gSendTo : String) {
        self.gName = gName
        self.gId = gId
        self.gAdmin = gAdmin
        self.gMember = gMember
        self.gSendTo = gSendTo
    }
    
    
    class func createGroup(withName:String,userIds:String,creatorID:String, completion:@escaping (Bool,String?,String?) -> Swift.Void){
        
        if let currentUserID = Auth.auth().currentUser?.uid {
             let values = ["name": withName, "admin": creatorID, "sendTo": userIds]
            let members = userIds.components(separatedBy: ",")
            
            
            Database.database().reference().child("groups").childByAutoId().setValue(values, withCompletionBlock: { (error, reference) in
                
                if error == nil{
                    Database.database().reference().child("groups").child(reference.key).child("member").setValue(members)
                    completion(true,reference.key,withName)
                }else{
                    completion(false,nil,nil)
                }
                
            })
        }
        
    }
    
    class func showGroups(completion: @escaping ([Group]) -> Swift.Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            var conversations = [Group]()
            
            Database.database().reference().child("groups").queryOrdered(byChild: "member").queryEqual(toValue: currentUserID).observe(.value, with: { snapshot in
                if  let value = snapshot.value as? NSDictionary {
                    
                    for (index,element) in value.enumerated(){
                        
                        if let value = element.value as? [String:Any]{
                            let gName = value["name"] as? String ?? ""
                            let admin = value["admin"] as? String ?? ""
                            let member = value["member"] as? [String] ?? [""]
                            let memberString = value["sendTo"] as? String ?? ""
                            let group = Group.init(gName: gName, gId: element.key as! String, gAdmin: admin, gMember: member, gSendTo: memberString)
                            conversations.append(group)
                        }
                        print(element)
                    }
                    
                    
                    completion(conversations)
                }
            })
//            Database.database().reference().child("groups").observeSingleEvent(of: .value, with: { (snapshot) in
//                if  let value = snapshot.value as? NSDictionary {
//                    
//                for (index,element) in value.enumerated(){
//                    
//                    if let value = element.value as? [String:Any]{
//                    let gName = value["name"] as? String ?? ""
//                    let admin = value["admin"] as? String ?? ""
//                    let member = value["member"] as? [String] ?? [""]
//                    let memberString = value["sendTo"] as? String ?? ""
//                    let group = Group.init(gName: gName, gId: element.key as! String, gAdmin: admin, gMember: member, gSendTo: memberString)
//                    conversations.append(group)
//                    }
//                    print(element)
//                }
//                
//                
//                completion(conversations)
//                }
//                
//            })
        }
        
        
    }
    
//    class func registerUser(withName: String, email: String, password: String, profilePic: UIImage, completion: @escaping (Bool) -> Swift.Void) {
//        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
//            if error == nil {
//                user?.sendEmailVerification(completion: nil)
//                let storageRef = Storage.storage().reference().child("usersProfilePics").child(user!.uid)
//                let imageData = UIImageJPEGRepresentation(profilePic, 0.1)
//                storageRef.putData(imageData!, metadata: nil, completion: { (metadata, err) in
//                    if err == nil {
//                        let path = metadata?.downloadURL()?.absoluteString
//                        let values = ["name": withName, "email": email, "profilePicLink": path!]
//                        Database.database().reference().child("users").child((user?.uid)!).child("credentials").updateChildValues(values, withCompletionBlock: { (errr, _) in
//                            if errr == nil {
//                                let userInfo = ["email" : email, "password" : password]
//                                UserDefaults.standard.set(userInfo, forKey: "userInformation")
//                                completion(true)
//                            }
//                        })
//                    }
//                })
//            }
//            else {
//                completion(false)
//            }
//        })
//    }
    
    
}
