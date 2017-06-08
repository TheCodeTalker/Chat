//
//  GroupConversion.swift
//  Chat
//
//  Created by Chitaranjan Sahu on 06/06/17.
//  Copyright © 2017 xelpmoc.in. All rights reserved.
//

import UIKit
import Firebase

class GroupConversion {
    let group : Group
    var lastMessage: GroupMessage
    
    init(group : Group,lastMessage: GroupMessage) {
        self.group = group
        self.lastMessage = lastMessage
    }
    
    class func showConversations(completion: @escaping ([GroupConversion]) -> Swift.Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            var conversations = [GroupConversion]()
            Database.database().reference().child("groups").observe(.childAdded, with: { (snapshot) in
                if snapshot.exists() {
                    let fromID = snapshot.key
                    let values = snapshot.value as! NSDictionary
                   // let location = values["location"]!
//                    let groupId = values["location"]!
                    
                   // if  let value = snapshot.value as? NSDictionary {
                        
                      //  for (index,element) in value.enumerated(){
                            
//if let value = element.value as? [String:Any]{
                                let gName = values["name"] as? String ?? ""
                                let admin = values["admin"] as? String ?? ""
                                let member = values["member"] as? [String] ?? [""]
                                let memberString = values["sendTo"] as? String ?? ""
                                if member.contains(currentUserID){
                                    let group = Group.init(gName: gName, gId: fromID, gAdmin: admin, gMember: member, gSendTo: memberString)
                                    let emptyMessage = GroupMessage.init(owner: .sender, type: .text, content: "loading", groupId: fromID, timestamp: 0, fromID: "",imagePath: "")
                                    let conversation = GroupConversion.init(group: group, lastMessage: emptyMessage)
                                    conversations.append(conversation)
                                    conversation.lastMessage.downloadLastMessage(groupId: fromID, completion: { (_) in
                                        completion(conversations)
                                    })
                                }
                                
                
                    
                    
//                    User.info(forUserID: fromID, completion: { (user) in
//                        let emptyMessage = Message.init(type: .text, content: "loading", owner: .sender, timestamp: 0, isRead: true)
//                        let conversation = Conversation.init(user: user, lastMessage: emptyMessage)
//                        conversations.append(conversation)
//                        conversation.lastMessage.downloadLastMessage(forLocation: location, completion: { (_) in
//                            completion(conversations)
//                        })
//                    })
                }
            })
        }
    }
    
    class func ReadMessagesRead(forGroupID: String,completion: @escaping (String) -> Swift.Void)  {
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("groupConversations").child(forGroupID).observeSingleEvent(of: .value, with: { (snapshot) in
                if snapshot.exists() {
                    var chat_history  = ""
                    for snap in snapshot.children {
                        let receivedMessage = (snap as! DataSnapshot).value as! [String: Any]
                        
                        let content = receivedMessage["content"]!
                        let timestamp = receivedMessage["timestamp"] as! Int
                        let messageType = receivedMessage["type"] as! String
                        let fromID = receivedMessage["fromID"] as! String
                        var type = MessageType.text
                        switch messageType {
                        case "text":
                            type = .text
                        case "photo":
                            type = .photo
                        case "location":
                            type = .location
                        default: break
                        }
                        
                       
                        
                        //self.type = type
                        chat_history = chat_history + "\(Date(milliseconds: timestamp)) : " + "  " + messageType + "   \(content)" + ". " + "\n"
                        
                        
                        //let last = value[value.count]
                        
                    }
                    completion(chat_history)
              
                }
            })
        }
    }
    

}
