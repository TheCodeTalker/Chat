//
//  ChatVC.swift
//  Chat
//
//  Created by Chitaranjan Sahu on 05/06/17.
//  Copyright © 2017 xelpmoc.in. All rights reserved.
//


import UIKit
import Photos
import Firebase
import CoreLocation
import AVFoundation
import Letters
import AVKit

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate,  UINavigationControllerDelegate, UIImagePickerControllerDelegate, CLLocationManagerDelegate,AVAudioRecorderDelegate {
    
    //MARK: Properties
    @IBOutlet var inputBar: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    override var inputAccessoryView: UIView? {
        get {
            self.inputBar.frame.size.height = self.barHeight
            self.inputBar.clipsToBounds = true
            return self.inputBar
        }
    }
    var nameDictonary = [Int:String]()
    var  audioRecorder:AVAudioRecorder?
    override var canBecomeFirstResponder: Bool{
        return true
    }
    let locationManager = CLLocationManager()
    var items = [GroupMessage]()
    let imagePicker = UIImagePickerController()
    let barHeight: CGFloat = 50
    var currentUser: String?
    var currentGroupName :String?
    var currentGroup:Group?
    var canSendLocation = true
    var userLoginInfo:User?
    var sendTo : String?
    var clickMessage : GroupMessage?
    

    //MARK: Methods
    func customization() {
        self.imagePicker.delegate = self
        self.tableView.estimatedRowHeight = self.barHeight
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.contentInset.bottom = self.barHeight
        self.tableView.scrollIndicatorInsets.bottom = self.barHeight
        self.navigationItem.title = self.currentGroupName
        self.navigationItem.setHidesBackButton(true, animated: false)
        let icon = UIImage.init(named: "back")?.withRenderingMode(.alwaysOriginal)
        let backButton = UIBarButtonItem.init(image: icon!, style: .plain, target: self, action: #selector(self.dismissSelf))
        self.navigationItem.leftBarButtonItem = backButton
        self.locationManager.delegate = self
    }
    
    //Downloads messages
    func fetchData() {
        GroupMessage.downloadAllMessages(forGroupID: self.currentUser!) { [weak weakSelf = self] (groupMessage) in
            weakSelf?.items.append(groupMessage)
            weakSelf?.items.sort{ $0.timestamp < $1.timestamp }
            DispatchQueue.main.async {
                if let state = weakSelf?.items.isEmpty, state == false {
                    weakSelf?.tableView.reloadData()
                    weakSelf?.tableView.scrollToRow(at: IndexPath.init(row: self.items.count - 1, section: 0), at: .bottom, animated: false)
                }
            }
        }
//        Message.downloadAllMessages(forUserID: self.currentUser!.id, completion: {[weak weakSelf = self] (message) in
//            weakSelf?.items.append(message)
//            weakSelf?.items.sort{ $0.timestamp < $1.timestamp }
//            DispatchQueue.main.async {
//                if let state = weakSelf?.items.isEmpty, state == false {
//                    weakSelf?.tableView.reloadData()
//                    weakSelf?.tableView.scrollToRow(at: IndexPath.init(row: self.items.count - 1, section: 0), at: .bottom, animated: false)
//                }
//            }
        
//        Message.markMessagesRead(forUserID: self.currentUser!.id)
    }
    
    //Hides current viewcontroller
    func dismissSelf() {
        if let navController = self.navigationController {
            navController.popViewController(animated: true)
        }
    }
    
    func composeMessage(type: MessageType, content: Any)  {
        
        if let id = Auth.auth().currentUser?.uid {
        
        let groupMessage = GroupMessage.init(owner: .sender, type: type, content: content, groupId: currentUser!, timestamp: Int(Date().timeIntervalSince1970), fromID: id, imagePath: "")
            if let sendTo = currentGroup?.gSendTo{
                GroupMessage.send(message: groupMessage, toID: (currentGroup?.gSendTo)!) { (_) in
                    
                }
            }else{
                GroupMessage.send(message: groupMessage, toID: sendTo!) { (_) in
                    
                }
            }
        
        }
        
        
        
//        let message = Message.init(type: type, content: content, owner: .sender, timestamp: Int(Date().timeIntervalSince1970), isRead: false)
//        
//        Message.send(message: message, toID: self.currentUser!, completion: {(_) in
//            
//        })
    }
    
    func checkLocationPermission() -> Bool {
        var state = false
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            state = true
        case .authorizedAlways:
            state = true
        default: break
        }
        return state
    }
    
    func animateExtraButtons(toHide: Bool)  {
        switch toHide {
        case true:
            self.bottomConstraint.constant = 0
            UIView.animate(withDuration: 0.3) {
                self.inputBar.layoutIfNeeded()
            }
        default:
            self.bottomConstraint.constant = -50
            UIView.animate(withDuration: 0.3) {
                self.inputBar.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func showMessage(_ sender: Any) {
       self.animateExtraButtons(toHide: true)
    }
    
    @IBAction func selectGallery(_ sender: Any) {
        self.animateExtraButtons(toHide: true)
        let status = PHPhotoLibrary.authorizationStatus()
        if (status == .authorized || status == .notDetermined) {
            self.imagePicker.sourceType = .savedPhotosAlbum;
            self.imagePicker.mediaTypes = ["public.image", "public.movie"]
            self.present(self.imagePicker, animated: true, completion: nil)
        }
        
    }
    
    @IBAction func selectCamera(_ sender: Any) {
        self.animateExtraButtons(toHide: true)
        let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if (status == .authorized || status == .notDetermined) {
            self.imagePicker.sourceType = .camera
            self.imagePicker.allowsEditing = false
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getAudiFileURL() -> URL {
        return getDocumentsDirectory().appendingPathComponent(".m4a")
    }
    func finishRecording(success: Bool) {
       
        
        if success {
            //recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
            //recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    func startRecording() {
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.low.rawValue
        ]
        
        do {
            let audioFileUrl = getAudiFileURL()
            audioRecorder = try AVAudioRecorder(url: audioFileUrl, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            // blackView.isHidden = false
        } catch {
            
            //finishRecording(success: false)
        }
    }
    
    func handleAudioSendWith(url: String) {
        guard let fileUrl = URL(string: url) else {
            return
        }
        let fileName = NSUUID().uuidString + ".m4a"
        
        Storage.storage().reference().child("message_voice").child(fileName).putFile(from: fileUrl, metadata: nil) { (metadata, error) in
            if error != nil {
                print(error ?? "error")
            }
            
            if let downloadUrl = metadata?.downloadURL()?.absoluteString {
                print(downloadUrl)
                let values: [String : Any] = ["audioUrl": downloadUrl]
                //self.sendMessageWith(properties: values)
            }
        }
    }
    
    @IBAction func selectVoice(_ sender: UIButton) {
        self.startRecording()
        
        
    }
    @IBAction func selectLocation(_ sender: Any) {
        self.canSendLocation = true
        self.animateExtraButtons(toHide: true)
        if self.checkLocationPermission() {
            self.locationManager.startUpdatingLocation()
        } else {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    @IBAction func showOptions(_ sender: Any) {
        self.animateExtraButtons(toHide: false)
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        if let text = self.inputTextField.text {
            if text.characters.count > 0 {
                self.composeMessage(type: .text, content: self.inputTextField.text!)
                self.inputTextField.text = ""
            }
        }
    }
    
    //MARK: NotificationCenter handlers
    func showKeyboard(notification: Notification) {
        if let frame = notification.userInfo![UIKeyboardFrameEndUserInfoKey] as? NSValue {
            let height = frame.cgRectValue.height
            self.tableView.contentInset.bottom = height
            self.tableView.scrollIndicatorInsets.bottom = height
            if self.items.count > 0 {
                self.tableView.scrollToRow(at: IndexPath.init(row: self.items.count - 1, section: 0), at: .bottom, animated: true)
            }
        }
    }

    //MARK: Delegates
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if tableView.isDragging {
            cell.transform = CGAffineTransform.init(scaleX: 0.5, y: 0.5)
            UIView.animate(withDuration: 0.3, animations: {
                cell.transform = CGAffineTransform.identity
            })
        }
    }
    
    func handlePlay(_ sender: UIButton) {
            var index = sender.tag
        
        if let videoUrlString = self.items[index].content as? String, let url = URL(string: videoUrlString) {
        //let videoURL = URL(string: "https://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.present(playerViewController, animated: true) {
            playerViewController.player!.play()
        }
        
        }
        
//        if let videoUrlString = message?.videoUrl, let url = URL(string: videoUrlString) {
//            player = AVPlayer(url: url)
//            
//            playerLayer = AVPlayerLayer(player: player)
//            playerLayer?.frame = bubbleView.bounds
//            bubbleView.layer.addSublayer(playerLayer!)
//            
//            player?.play()
//            activityIndicatorView.startAnimating()
//            playButton.isHidden = true
//            
//            print("Attempting to play video......???")
//        }
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch self.items[indexPath.row].owner {
        case .receiver:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Receiver", for: indexPath) as! ReceiverCell
            cell.clearCellData()
            switch self.items[indexPath.row].type {
            case .text:
                cell.message.text = self.items[indexPath.row].content as! String
              //  cell.message.backgroundColor = UIColor(red: 228/255, green: 253/255, blue: 198/255, alpha: 1)
            case .photo:
                if let image = self.items[indexPath.row].image {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                    cell.playBtn.isHidden = true
                } else {
                     cell.playBtn.isHidden = true
                    cell.messageBackground.image = UIImage.init(named: "loading")
                    self.items[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
                        if state == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
            case .location:
                cell.messageBackground.image = UIImage.init(named: "location")
                cell.message.isHidden = true
                cell.playBtn.isHidden = true
                
            case .audio:
                break
            case .video:
                if let image = self.items[indexPath.row].image {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                    cell.playBtn.isHidden = false
                } else {
                    cell.messageBackground.image = UIImage.init(named: "loading")
                   // cell.videoView.isHidden = true
                    cell.playBtn.isHidden = false
                    cell.playBtn.tag = indexPath.item
                    cell.playBtn.addTarget(self, action: #selector(ChatVC.handlePlay), for: .touchUpInside)
                    
                    self.items[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
                        if state == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
                
                break
                
            }
            return cell
        case .sender:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Sender", for: indexPath) as! SenderCell
            cell.clearCellData()
            if let userName =  self.nameDictonary[indexPath.item]{
                cell.profilePic.setImage(string: userName, color: UIColor(red: 134/255, green: 139/255, blue: 254/255, alpha: 1), circular: true)
            
            }else{
                fetchUser(userID: self.items[indexPath.row].fromID, completion: { [weak weakSelf = self] (user) in
                    DispatchQueue.main.async {
                        
                        cell.profilePic.setImage(string: user.name, color: UIColor(red: 134/255, green: 139/255, blue: 254/255, alpha: 1), circular: true)
                    }
                    self.nameDictonary[indexPath.item] = user.name
                })
            }
            
           // fetchUser(userID: self.items[indexPath.row].fromID,completion: )
//            if let userLoginInfo = self.userLoginInfo{
//               
//            }
            
           // cell.profilePic.image = UIImage.init(named: "default profile")
            switch self.items[indexPath.row].type {
            case .text:
                cell.message.text = self.items[indexPath.row].content as! String
               // cell.message.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
            case .photo:
                if let image = self.items[indexPath.row].image {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                    cell.playBtn.isHidden = true
                } else {
                    cell.playBtn.isHidden = true
                    cell.messageBackground.image = UIImage.init(named: "loading")
                    self.items[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
                        if state == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
            case .location:
                cell.messageBackground.image = UIImage.init(named: "location")
                cell.message.isHidden = true
                cell.playBtn.isHidden = true
            case .audio:
                break
            case .video:
                
                
                
                
                if let image = self.items[indexPath.row].image {
                    cell.messageBackground.image = image
                    cell.message.isHidden = true
                    cell.playBtn.isHidden = false
                } else {
                    cell.playBtn.isHidden = false
                    cell.messageBackground.image = UIImage.init(named: "loading")
                  //  cell.videoView.isHidden = true
                    cell.playBtn.tag = indexPath.item
                    cell.playBtn.addTarget(self, action: #selector(ChatVC.handlePlay), for: .touchUpInside)
                    
                   self.items[indexPath.row].downloadImage(indexpathRow: indexPath.row, completion: { (state, index) in
                        if state == true {
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
                
                break
                
            }
            return cell
        }
    }
    

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.inputTextField.resignFirstResponder()
        switch self.items[indexPath.row].type {
        case .photo:
            if let photo = self.items[indexPath.row].image {
                let info = ["viewType" : ShowExtraView.preview, "pic": photo] as [String : Any]
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
                self.inputAccessoryView?.isHidden = true
            }
        case .location:
            let coordinates = (self.items[indexPath.row].content as! String).components(separatedBy: ":")
            let location = CLLocationCoordinate2D.init(latitude: CLLocationDegrees(coordinates[0])!, longitude: CLLocationDegrees(coordinates[1])!)
            let info = ["viewType" : ShowExtraView.map, "location": location] as [String : Any]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showExtraView"), object: nil, userInfo: info)
            self.inputAccessoryView?.isHidden = true
        default: break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.composeMessage(type: .photo, content: pickedImage)
        } else if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage{
            
            self.composeMessage(type: .photo, content: pickedImage)
        }else if let videoURL = info[UIImagePickerControllerMediaURL]as? NSURL{
            
            
            self.composeMessage(type: .video, content: videoURL)
            
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        if let lastLocation = locations.last {
            if self.canSendLocation {
                let coordinate = String(lastLocation.coordinate.latitude) + ":" + String(lastLocation.coordinate.longitude)
                
                let groupMessage = GroupMessage.init(owner: .sender, type: .location, content: coordinate, groupId: currentUser!, timestamp: Int(Date().timeIntervalSince1970), fromID: currentUser!, imagePath: "")
                GroupMessage.send(message: groupMessage, toID: (currentGroup?.gSendTo)!) { (_) in
                    
                }

                
//                let message = Message.init(type: .location, content: coordinate, owner: .sender, timestamp: Int(Date().timeIntervalSince1970), isRead: false)
//                Message.send(message: message, toID: self.currentUser!, completion: {(_) in
//                })
                self.canSendLocation = false
            }
        }
    }

    //MARK: ViewController lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.inputBar.backgroundColor = UIColor.clear
        self.view.layoutIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(ChatVC.showKeyboard(notification:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
      //  Message.markMessagesRead(forUserID: self.currentUser!)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tempImageView = UIImageView(image: UIImage(named: "back-1"))
        tempImageView.frame = self.tableView.frame
        tempImageView.alpha = 0.3
        self.tableView.backgroundView = tempImageView
        self.customization()
       // self.fetchUser()
        self.fetchData()
    }
    func fetchUser(userID:String,completion: @escaping (User) -> Swift.Void) {
        
         //if let id = Auth.auth().currentUser?.uid {
            
        User.info(forUserID: userID, completion: { (user) in
            
          //  self.userLoginInfo = user
//            DispatchQueue.main.async {
//                self.tableView.reloadData()
//            }
            completion(user)
            
//            let emptyMessage = Message.init(type: .text, content: "loading", owner: .sender, timestamp: 0, isRead: true)
//            let conversation = Conversation.init(user: user, lastMessage: emptyMessage)
//            conversations.append(conversation)
//            conversation.lastMessage.downloadLastMessage(forLocation: location, completion: { (_) in
//                completion(conversations)
//            })
        })
        //}


    }
    
    
}



