//
//  GroupMessage.swift
//  Chat
//
//  Created by Chitaranjan Sahu on 06/06/17.
//  Copyright © 2017 xelpmoc.in. All rights reserved.
//

import UIKit
import Firebase
import AVFoundation

class GroupMessage {
    
    var owner: MessageOwner
    var type: MessageType
    var content: Any
    var groupId :String
    var timestamp: Int
    var image: UIImage?
     var toID: String?
    var fromID: String
    var imagePath :String?
  
    
    init(owner: MessageOwner,type: MessageType,content: Any,groupId :String,timestamp: Int,fromID: String,imagePath:String?) {
        self.owner = owner
        self.type  = type
        self.content = content
        self.groupId = groupId
        self.timestamp = timestamp
        self.fromID = fromID
        self.imagePath = imagePath
    }
    
    func downloadImage(indexpathRow: Int, completion: @escaping (Bool, Int) -> Swift.Void)  {
        if self.type == .photo {
            let imageLink = self.content as! String
            let imageURL = URL.init(string: imageLink)
            URLSession.shared.dataTask(with: imageURL!, completionHandler: { (data, response, error) in
                if error == nil {
                    self.image = UIImage.init(data: data!)
                    completion(true, indexpathRow)
                }
            }).resume()
        }else if self.type == .video {
            
            let imageLink = imagePath
            let imageURL = URL.init(string: imageLink!)
            URLSession.shared.dataTask(with: imageURL!, completionHandler: { (data, response, error) in
                if error == nil {
                    self.image = UIImage.init(data: data!)
                    completion(true, indexpathRow)
                }
            }).resume()
            
//            let imageLink = self.content as! String
//            let imageURL = URL.init(string: imageLink)
//
//            let asset = AVAsset(url: imageURL!)
//            let imageGenerator = AVAssetImageGenerator(asset: asset)
//            
//            do {
//                
//                let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
//                DispatchQueue.main.async {
//                self.image  =  UIImage(cgImage: thumbnailCGImage)
//                }
//                completion(true, indexpathRow)
//                
//            } catch let err {
//                print(err)
//            }
            
         //   return nil

        
          
            
            
        }
        
    }

    
    func downloadLastMessage(groupId: String, completion: @escaping (Void) -> Swift.Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("groupConversations").child(groupId).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    if  let valueeee = snapshot.value as? NSDictionary {
                        
                     let last = valueeee.allValues.last as! [String: Any]
                        
                        self.content = last["content"]!
                        self.timestamp = last["timestamp"] as! Int
                        let messageType = last["type"] as! String
                        let fromID = last["fromID"] as! String
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
                        self.type = type
                        if currentUserID == fromID {
                            self.owner = .receiver
                        } else {
                            self.owner = .sender
                        }
                        completion()

                       
                        //let last = value[value.count]
                        
                    }
//                    for snap in snapshot.children {
//                        let receivedMessage = (snap as! DataSnapshot).value as! [String: Any]
//                        self.content = receivedMessage["content"]!
//                        self.timestamp = receivedMessage["timestamp"] as! Int
//                        let messageType = receivedMessage["type"] as! String
//                        let fromID = receivedMessage["fromID"] as! String
//                        var type = MessageType.text
//                        switch messageType {
//                        case "text":
//                            type = .text
//                        case "photo":
//                            type = .photo
//                        case "location":
//                            type = .location
//                        default: break
//                        }
//                        self.type = type
//                        if currentUserID == fromID {
//                            self.owner = .receiver
//                        } else {
//                            self.owner = .sender
//                        }
//                        completion()
//                    }
//                }else{
//                    completion()
//                }
                }else{
                    completion()
                }
            })
        }
    }
    
    
    
    class func send(message: GroupMessage, toID: String, completion: @escaping (Bool) -> Swift.Void)  {
        if let currentUserID = Auth.auth().currentUser?.uid {
            switch message.type {
            case .location:
                let values = ["type": "location", "content": message.content, "fromID": currentUserID, "groupId": toID, "timestamp": message.timestamp]
                GroupMessage.uploadMessage(withValues: values, toID: toID, groupId: message.groupId, completion: { (status) in
                    completion(status)
                })
            case .photo:
                let imageData = UIImageJPEGRepresentation((message.content as! UIImage), 0.5)
                let child = UUID().uuidString
                Storage.storage().reference().child("messagePics").child(child).putData(imageData!, metadata: nil, completion: { (metadata, error) in
                    if error == nil {
                        let path = metadata?.downloadURL()?.absoluteString
                        let values = ["type": "photo", "content": path!, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false] as [String : Any]
                        GroupMessage.uploadMessage(withValues: values, toID: toID, groupId: message.groupId, completion: { (status) in
                            completion(status)
                        })
                    }
                })
            case .text:
                let values = ["type": "text", "content": message.content, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp]
                GroupMessage.uploadMessage(withValues: values, toID: toID, groupId: message.groupId, completion: { (status) in
                    completion(status)
                })
                
            case .audio:
                break
            case .video:
                let urlString = message.content as! URL
                let filename = UUID().uuidString + ".mov"
                let uploadTask = Storage.storage().reference().child("messageVideo").child(filename).putFile(from: urlString, metadata: nil, completion: { (metadata, error) in
                    
                    if error != nil {
                        print("Failed upload of video:", error!)
                        return
                    }
                    
                    if let videoUrl = metadata?.downloadURL()?.absoluteString {
                        if let thumbnailImage = thumbnailImageForFileUrl(urlString) {
                             let data = UIImageJPEGRepresentation(thumbnailImage, 0.5)
                            Storage.storage().reference().child("messagePics").child(UUID().uuidString).putData(data!, metadata: nil, completion: { (metadata, error) in
                                if error == nil {
                                    let path = metadata?.downloadURL()?.absoluteString

                            let values = ["type": "video", "content": videoUrl, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "imagePath": path] as [String : Any]
                            GroupMessage.uploadMessage(withValues: values, toID: toID, groupId: message.groupId, completion: { (status) in
                                completion(status)
                            })
                                }
                            })
                            
//                            
//                            self.uploadToFirebaseStorageUsingImage(thumbnailImage, completion: { (imageUrl) in
//                                let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight": thumbnailImage.size.height as AnyObject, "videoUrl": videoUrl as AnyObject]
//                                self.sendMessageWithProperties(properties)
//                                
//                            })
                        }
                    }
                })
                
                uploadTask.observe(.progress) { (snapshot) in
                    if let completedUnitCount = snapshot.progress?.completedUnitCount {
                        
                          print(String(completedUnitCount)) 
                    }
                }
                
                uploadTask.observe(.success) { (snapshot) in
                    //   self.navigationItem.title = self.user?.name
                }
                //handleVideoSelectedForUrl(url: urlString)
                
                break
            }
        }
    }
    
    
    class func thumbnailImageForFileUrl(_ fileUrl: URL) -> UIImage? {
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
            
        } catch let err {
            print(err)
        }
        
        return nil
    }
    
//   class  func handleVideoSelectedForUrl(url: URL) {
//        let filename = UUID().uuidString + ".mov"
//        let uploadTask = Storage.storage().reference().child("messageVideo").child(filename).putFile(from: url, metadata: nil, completion: { (metadata, error) in
//            
//            if error != nil {
//                print("Failed upload of video:", error!)
//                return
//            }
//            
//            if let videoUrl = metadata?.downloadURL()?.absoluteString {
//                if let thumbnailImage = thumbnailImageForFileUrl(url) {
//                    
//                    
//                    let values = ["type": "video", "content": thumbnailImage, "fromID": currentUserID, "toID": toID, "timestamp": message.timestamp, "isRead": false] as [String : Any]
//                    GroupMessage.uploadMessage(withValues: values, toID: toID, groupId: message.groupId, completion: { (status) in
//                        completion(status)
//                    })
//                    
//                    
//                    self.uploadToFirebaseStorageUsingImage(thumbnailImage, completion: { (imageUrl) in
//                        let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbnailImage.size.width as AnyObject, "imageHeight": thumbnailImage.size.height as AnyObject, "videoUrl": videoUrl as AnyObject]
//                        self.sendMessageWithProperties(properties)
//                        
//                    })
//                }
//            }
//        })
//        
//        uploadTask.observe(.progress) { (snapshot) in
//            if let completedUnitCount = snapshot.progress?.completedUnitCount {
//              //  self.navigationItem.title = String(completedUnitCount)
//            }
//        }
//        
//        uploadTask.observe(.success) { (snapshot) in
//         //   self.navigationItem.title = self.user?.name
//        }
//    }
    
    class func downloadAllMessages(forGroupID: String, completion: @escaping (GroupMessage) -> Swift.Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            
           Database.database().reference().child("groupConversations").child(forGroupID).observe(.childAdded, with: { (snap) in
            
            if snap.exists() {
                let receivedMessage = snap.value as! [String: Any]
                let messageType = receivedMessage["type"] as! String
                 var imagePath = ""
                var type = MessageType.text
                switch messageType {
                case "photo":
                    type = .photo
                case "location":
                    type = .location
                case "video":
                    type = .video
                    imagePath = receivedMessage["imagePath"] as! String
                default: break
                }
                
                let content = receivedMessage["content"] as! String
                let fromID = receivedMessage["fromID"] as! String
                let timestamp = receivedMessage["timestamp"] as! Int
                if fromID == currentUserID {
                    let message = GroupMessage.init(owner: .receiver, type: type, content: content, groupId: "", timestamp: timestamp,fromID:fromID,imagePath: imagePath)
                    completion(message)
                } else {
                    let message = GroupMessage.init(owner: .sender, type: type, content: content, groupId: "", timestamp: timestamp, fromID:fromID,imagePath: imagePath)
                    completion(message)
                }

            }
            
           })
            
//            Database.database().reference().child("users").child(currentUserID).child("conversations").child(forUserID).observe(.value, with: { (snapshot) in
//                if snapshot.exists() {
//                    let data = snapshot.value as! [String: String]
//                    let location = data["location"]!
//                    Database.database().reference().child("conversations").child(location).observe(.childAdded, with: { (snap) in
//                        if snap.exists() {
//                            let receivedMessage = snap.value as! [String: Any]
//                            let messageType = receivedMessage["type"] as! String
//                            var type = MessageType.text
//                            switch messageType {
//                            case "photo":
//                                type = .photo
//                            case "location":
//                                type = .location
//                            default: break
//                            }
//                            let content = receivedMessage["content"] as! String
//                            let fromID = receivedMessage["fromID"] as! String
//                            let timestamp = receivedMessage["timestamp"] as! Int
//                            if fromID == currentUserID {
//                                let message = Message.init(type: type, content: content, owner: .receiver, timestamp: timestamp, isRead: true)
//                                completion(message)
//                            } else {
//                                let message = Message.init(type: type, content: content, owner: .sender, timestamp: timestamp, isRead: true)
//                                completion(message)
//                            }
//                        }
//                    })
//                }
//            })
        }
    }
    
    func downloadLastMessage(forLocation: String, completion: @escaping (Void) -> Swift.Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            Database.database().reference().child("groupConversations").child(forLocation).observe(.value, with: { (snapshot) in
                if snapshot.exists() {
                    for snap in snapshot.children {
                        let receivedMessage = (snap as! DataSnapshot).value as! [String: Any]
                        self.content = receivedMessage["content"]!
                        self.timestamp = receivedMessage["timestamp"] as! Int
                        let messageType = receivedMessage["type"] as! String
                        let fromID = receivedMessage["fromID"] as! String
                        //self.isRead = receivedMessage["isRead"] as! Bool
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
                        self.type = type
                        if currentUserID == fromID {
                            self.owner = .receiver
                        } else {
                            self.owner = .sender
                        }
                        completion()
                    }
                }
            })
        }
    }
    
    
    
    class func uploadMessage(withValues: [String: Any], toID: String,groupId: String, completion: @escaping (Bool) -> Swift.Void) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            
            
            Database.database().reference().child("groupConversations").child(groupId).childByAutoId().setValue(withValues, withCompletionBlock: { (error, reference) in
                if error == nil{
                    completion(true)
                }else{
                    completion(false)
                }
            })
            
            
                     }
    }

}
