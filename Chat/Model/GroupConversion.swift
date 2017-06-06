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
    var lastMessage: Message
    
    init(group : Group,lastMessage: Message) {
        self.group = group
        self.lastMessage = lastMessage
    }
    
//    class func showConversations(completion: @escaping ([Conversation]) -> Swift.Void) {
//        if let currentUserID = Auth.auth().currentUser?.uid {
//            var conversations = [GroupConversion]()
//            Database.database().reference().child("conversations").observe(.childAdded, with: { (snapshot) in
//                if snapshot.exists() {
//                    let fromID = snapshot.key
//                    let values = snapshot.value as! [String: String]
//                    let location = values["location"]!
//                    User.info(forUserID: fromID, completion: { (user) in
//                        let emptyMessage = Message.init(type: .text, content: "loading", owner: .sender, timestamp: 0, isRead: true)
//                        let conversation = Conversation.init(user: user, lastMessage: emptyMessage)
//                        conversations.append(conversation)
//                        conversation.lastMessage.downloadLastMessage(forLocation: location, completion: { (_) in
//                            completion(conversations)
//                        })
//                    })
//                }
//            })
//        }
//    }
    

}
