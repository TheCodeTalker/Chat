//
//  ConversationsVC.swift
//  Chat
//
//  Created by Chitaranjan Sahu on 05/06/17.
//  Copyright © 2017 xelpmoc.in. All rights reserved.
//

import UIKit
import Firebase
import AudioToolbox
import MBProgressHUD
import MessageUI
class ConversationsVC: UIViewController, UITableViewDelegate, UITableViewDataSource,MFMailComposeViewControllerDelegate {
    
    //MARK: Properties
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var alertBottomConstraint: NSLayoutConstraint!
    lazy var leftButton: UIBarButtonItem = {
        let image = UIImage.init(named: "default profile")?.withRenderingMode(.alwaysOriginal)
        let button  = UIBarButtonItem.init(image: image, style: .plain, target: self, action: #selector(ConversationsVC.showProfile))
        return button
    }()
    var items = [GroupConversion]()
    var selectedGroup: String?
    var selectedName: String?
    var sendTo :String?
    var currentGroup :Group?
    let mailComposer = MFMailComposeViewController()
    var deleteGroup :GroupConversion?
    var deleteIndex :Int?
    
    
    //MARK: Methods
    func customization()  {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        //NavigationBar customization
        let navigationTitleFont = UIFont(name: "AvenirNext-Regular", size: 18)!
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: navigationTitleFont, NSForegroundColorAttributeName: UIColor.white]
        // notification setup
        NotificationCenter.default.addObserver(self, selector: #selector(self.pushToUserMesssages(notification:)), name: NSNotification.Name(rawValue: "showUserMessages"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.showEmailAlert), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        //right bar button
        let icon = UIImage.init(named: "compose")?.withRenderingMode(.alwaysOriginal)
      //  let rightButton = UIBarButtonItem.init(image: icon!, style: .plain, target: self, action: #selector(ConversationsVC.showContacts))
        
        let addGroup = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(ConversationsVC.addGroup))
        //let rightButton = UIBarButtonItem.init(image: , style: .plain, target: self, action: #selector(ConversationsVC.showContacts))
        
        self.navigationItem.rightBarButtonItems = [addGroup]
        //self.navigationItem.rightBarButtonItem = rightButton
        //left bar button image fetching
        self.navigationItem.leftBarButtonItem = self.leftButton
        self.tableView.tableFooterView = UIView.init(frame: CGRect.zero)
        if let id = Auth.auth().currentUser?.uid {
            User.info(forUserID: id, completion: { [weak weakSelf = self] (user) in
                let image = user.profilePic
                let contentSize = CGSize.init(width: 30, height: 30)
                UIGraphicsBeginImageContextWithOptions(contentSize, false, 0.0)
                let _  = UIBezierPath.init(roundedRect: CGRect.init(origin: CGPoint.zero, size: contentSize), cornerRadius: 14).addClip()
                image.draw(in: CGRect(origin: CGPoint.zero, size: contentSize))
                let path = UIBezierPath.init(roundedRect: CGRect.init(origin: CGPoint.zero, size: contentSize), cornerRadius: 14)
                path.lineWidth = 2
                UIColor.white.setStroke()
                path.stroke()
                let finalImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!.withRenderingMode(.alwaysOriginal)
                UIGraphicsEndImageContext()
                DispatchQueue.main.async {
                    weakSelf?.leftButton.image = finalImage
                    weakSelf = nil
                }
            })
        }
    }
    
    //Downloads conversations
    func fetchData() {
        
//        Group.showGroups { (group) in
//            
//                        self.items = group
//                       // self.items.sort{ $0.lastMessage.timestamp > $1.lastMessage.timestamp }
//                        DispatchQueue.main.async {
//                            self.tableView.reloadData()
//                            self.playSound()
//
//                        }
//
//            
//        }
        
        
        GroupConversion.showConversations { (conversations) in
            self.items = conversations
            self.items.sort{ $0.lastMessage.timestamp > $1.lastMessage.timestamp }
            DispatchQueue.main.async {
                self.tableView.reloadData()
                for conversation in self.items {
                    //if conversation.lastMessage.isRead == false {
                        self.playSound()
                        break
                    //}
                }
            }
        }
        
        
    }
    
    //Shows profile extra view
    func showProfile() {
        let info = ["viewType" : ShowExtraView.profile]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
        self.inputView?.isHidden = true
    }
    
    //Shows contacts extra view
    func showContacts() {
        let info = ["viewType" : ShowExtraView.contacts]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
    }
    func addGroup() {
        
        let info = ["viewType" : ShowExtraView.group]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
        
       // let info = ["viewType" : ShowExtraView.contacts]
        
       // NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
    }
    
    
    //Show EmailVerification on the bottom
    func showEmailAlert() {
        User.checkUserVerification {[weak weakSelf = self] (status) in
            status == true ? (weakSelf?.alertBottomConstraint.constant = -40) : (weakSelf?.alertBottomConstraint.constant = 0)
            UIView.animate(withDuration: 0.3) {
                weakSelf?.view.layoutIfNeeded()
                weakSelf = nil
            }
        }
    }
    
    //Shows Chat viewcontroller with given user
    func pushToUserMesssages(notification: NSNotification) {
        if let groupId = notification.userInfo?["groupID"] as? String,let groupName = notification.userInfo?["groupName"] as? String, let sendTo = notification.userInfo?["sendTo"] as? String  {
            
            
           self.selectedGroup = groupId
            self.selectedName = groupName
            self.sendTo = sendTo
            self.performSegue(withIdentifier: "segue", sender: self)
        }
    }
    
    func playSound()  {
        var soundURL: NSURL?
        var soundID:SystemSoundID = 0
        let filePath = Bundle.main.path(forResource: "newMessage", ofType: "wav")
        soundURL = NSURL(fileURLWithPath: filePath!)
        AudioServicesCreateSystemSoundID(soundURL!, &soundID)
        AudioServicesPlaySystemSound(soundID)
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segue" {
            let vc = segue.destination as! ChatVC
            vc.currentGroupName = self.selectedName
            vc.currentUser = self.selectedGroup
            vc.currentGroup = self.currentGroup
            vc.sendTo = self.sendTo
        }
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        if  self.items.count != 0{
        let groups = self.items[indexPath.item]
          if let id = Auth.auth().currentUser?.uid {
        
            if groups.group.gAdmin == id{
                 return true
            }
        }
        }
       return false
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            self.deleteGroup = self.items[indexPath.item]
            self.deleteIndex = indexPath.item
            self.createChatCopyOfGroup(ForGroupId: self.items[indexPath.item])
            
            
        }
    }
    
    
    func createChatCopyOfGroup(ForGroupId:GroupConversion)
    {
       // let filename = "chatfile"
        //let strings = ["a","b"]
        
        GroupConversion.ReadMessagesRead(forGroupID: ForGroupId.group.gId!) { [weak weekself = self](text) in
            if(MFMailComposeViewController.canSendMail()){
                
                
                weekself?.mailComposer.mailComposeDelegate = self
                // mailComposer.setToRecipients([mail])
                weekself?.mailComposer.setSubject("Subject" )
                weekself?.mailComposer.setMessageBody("body text", isHTML: false)
                
              //  let joinedString = strings.joined(separator: "\n")
               // print(joinedString)
                if let data = (text as NSString).data(using: String.Encoding.utf8.rawValue){
                    //Attach File
                    weekself?.mailComposer.addAttachmentData(data, mimeType: "text/plain", fileName: "ChatHistory")
                    weekself?.present(self.mailComposer, animated: true, completion: nil)
                }
            }

        }
        
        
    }
    
    func myDeleteFunction(childIWantToRemove: String,completion: @escaping (Bool) -> Swift.Void) {
        
        Database.database().reference().child("groups").child(childIWantToRemove).removeValue { (error, ref) in
            if error != nil {
        Database.database().reference().child("groupConversations").child(childIWantToRemove).removeValue { (error, ref) in
              if error != nil {
                completion(true)
                
            }
                }
                print("error \(error)")
            }
        }
        completion(false)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        switch (result)
        {
        case .cancelled:
            deleteGroup = nil
            deleteIndex = nil
            mailComposer.dismiss(animated: true, completion: nil)

            //NSLog(@"Mail cancelled");
            break;
        case .saved:
            
            mailComposer.dismiss(animated: true, completion: nil)

            //NSLog(@"Mail saved");
            break;
        case .sent:
            
            mailComposer.dismiss(animated: true, completion: {
                if let index = self.deleteIndex{
                    
                    
                    self.myDeleteFunction(childIWantToRemove: (self.deleteGroup?.group.gId)!, completion: { (flag) in
                        if flag != false{
                        self.tableView.beginUpdates()
                        
                        self.items.remove(at: index)
                        let indexPath = IndexPath(row: index, section: 0)
                        // Note that indexPath is wrapped in an array:  [indexPath]
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                        
                        self.deleteIndex = nil
                        // self.tableView.reloadData()
                        
                        self.tableView.endUpdates()
                        }

                    })
                    
                }

            })
           // mailComposer.dismiss(animated: true, completion: nil)
            
            

            
            

            //NSLog(@"Mail sent");
            break;
        case .failed:
            mailComposer.dismiss(animated: true, completion: nil)

            //NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
        }
            }
    
    
    
    
    
    
    
    
    
      //MARK: Delegates
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.items.count == 0 {
            return 1
        } else {
            return self.items.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if self.items.count == 0 {
            return self.view.bounds.height - self.navigationController!.navigationBar.bounds.height
        } else {
            return 80
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.items.count {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Empty Cell")!
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! ConversationsTBCell
            cell.clearCellData()
            cell.profilePic.image = UIImage.init(named: "default profile")
            cell.nameLabel.text = self.items[indexPath.row].group.gName
//            switch self.items[indexPath.row].lastMessage.type {
//            case .text:
//                let message = self.items[indexPath.row].lastMessage.content as! String
//                cell.messageLabel.text = message
//            case .location:
//                cell.messageLabel.text = "Location"
//            default:
//                cell.messageLabel.text = "Media"
//            }
            let messageDate = Date.init(timeIntervalSince1970: TimeInterval(5))
            let dataformatter = DateFormatter.init()
            dataformatter.timeStyle = .short
            let date = dataformatter.string(from: messageDate)
            cell.timeLabel.text = date
//            if self.items[indexPath.row].lastMessage.owner == .sender && self.items[indexPath.row].lastMessage.isRead == false {
//                cell.nameLabel.font = UIFont(name:"AvenirNext-DemiBold", size: 17.0)
//                cell.messageLabel.font = UIFont(name:"AvenirNext-DemiBold", size: 14.0)
//                cell.timeLabel.font = UIFont(name:"AvenirNext-DemiBold", size: 13.0)
//                cell.profilePic.layer.borderColor = GlobalVariables.blue.cgColor
//                cell.messageLabel.textColor = GlobalVariables.purple
//            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.items.count > 0 {
            
            self.selectedGroup = self.items[indexPath.row].group.gId
            self.currentGroup = self.items[indexPath.item].group
            self.performSegue(withIdentifier: "segue", sender: self)
        }
    }
       
    //MARK: ViewController lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customization()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.showEmailAlert()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchData()
        if let selectionIndexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: selectionIndexPath, animated: animated)
        }
    }
}





