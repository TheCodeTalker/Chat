//
//  NavVC.swift
//  Chat
//
//  Created by Chitaranjan Sahu on 05/06/17.
//  Copyright © 2017 xelpmoc.in. All rights reserved.
//

import UIKit
import Firebase
import MapKit
import BEMCheckBox

class NavVC: UINavigationController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate,BEMCheckBoxDelegate {

    //MARK: Properties
    @IBOutlet var contactsView: UIView!
    @IBOutlet var profileView: UIView!
    @IBOutlet var previewView: UIView!
    @IBOutlet var mapPreviewView: UIView!
    @IBOutlet weak var mapVIew: MKMapView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profilePicView: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var creationBtn: RoundedButton!
    @IBOutlet weak var closeBtn: UIButton!
    var TypeOfView : ShowExtraView?
    var topAnchorContraint: NSLayoutConstraint!
    let darkView = UIView.init()
    var items = [User]()
    
    var groupMemeber = [Int:String]()
    
    //MARK: Methods
    func customization() {
        //DarkView customization
        self.view.addSubview(self.darkView)
        self.darkView.backgroundColor = UIColor.black
        self.darkView.alpha = 0
        self.darkView.translatesAutoresizingMaskIntoConstraints = false
        self.darkView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.darkView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.darkView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.darkView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        self.darkView.isHidden = true
    //ContainerView customization
        let extraViewsContainer = UIView.init()
        extraViewsContainer.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(extraViewsContainer)
        self.topAnchorContraint = NSLayoutConstraint.init(item: extraViewsContainer, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 1000)
        self.topAnchorContraint.isActive = true
        extraViewsContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        extraViewsContainer.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        extraViewsContainer.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: 1).isActive = true
        extraViewsContainer.backgroundColor = UIColor.clear
    //ContactsView customization
        extraViewsContainer.addSubview(self.contactsView)
        self.contactsView.translatesAutoresizingMaskIntoConstraints = false
        self.contactsView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.contactsView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.contactsView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.contactsView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        self.contactsView.isHidden = true
        self.collectionView?.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        self.contactsView.backgroundColor = UIColor.clear
    //ProfileView Customization
        extraViewsContainer.addSubview(self.profileView)
        self.profileView.translatesAutoresizingMaskIntoConstraints = false
        self.profileView.heightAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width * 0.9)).isActive = true
        let profileViewAspectRatio = NSLayoutConstraint.init(item: self.profileView, attribute: .width, relatedBy: .equal, toItem: self.profileView, attribute: .height, multiplier: 0.8125, constant: 0)
        profileViewAspectRatio.isActive = true
        self.profileView.centerXAnchor.constraint(equalTo: extraViewsContainer.centerXAnchor).isActive = true
        self.profileView.centerYAnchor.constraint(equalTo: extraViewsContainer.centerYAnchor).isActive = true
        self.profileView.layer.cornerRadius = 5
        self.profileView.clipsToBounds = true
        self.profileView.isHidden = true
        self.profilePicView.layer.borderColor = GlobalVariables.purple.cgColor
        self.profilePicView.layer.borderWidth = 3
        self.view.layoutIfNeeded()
    //PreviewView Customization
        extraViewsContainer.addSubview(self.previewView)
        self.previewView.isHidden = true
        self.previewView.translatesAutoresizingMaskIntoConstraints = false
        self.previewView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.previewView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.previewView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.previewView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        self.scrollView.minimumZoomScale = 1.0
        self.scrollView.maximumZoomScale = 3.0
    //MapPreView Customization
        extraViewsContainer.addSubview(self.mapPreviewView)
        self.mapPreviewView.isHidden = true
        self.mapPreviewView.translatesAutoresizingMaskIntoConstraints = false
        self.mapPreviewView.leadingAnchor.constraint(equalTo: extraViewsContainer.leadingAnchor).isActive = true
        self.mapPreviewView.topAnchor.constraint(equalTo: extraViewsContainer.topAnchor).isActive = true
        self.mapPreviewView.trailingAnchor.constraint(equalTo: extraViewsContainer.trailingAnchor).isActive = true
        self.mapPreviewView.bottomAnchor.constraint(equalTo: extraViewsContainer.bottomAnchor).isActive = true
        //NotificationCenter for showing extra views
        NotificationCenter.default.addObserver(self, selector: #selector(self.showExtraViews(notification:)), name: NSNotification.Name(rawValue: "showExtraView"), object: nil)
        self.fetchUsers()
        self.fetchUserInfo()

    }
    
    //Hide Extra views
    func dismissExtraViews() {
        TypeOfView = nil
        self.topAnchorContraint.constant = 1000
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
            self.darkView.alpha = 0
            self.view.transform = CGAffineTransform.identity
        }, completion:  { (true) in
            self.darkView.isHidden = true
            self.profileView.isHidden = true
            self.contactsView.isHidden = true
            self.previewView.isHidden = true
            self.mapPreviewView.isHidden = true
            self.mapVIew.removeAnnotations(self.mapVIew.annotations)
            let vc = self.viewControllers.last
            vc?.inputAccessoryView?.isHidden = false
        })
    }
    
    @IBAction func closeBtnClicked(_ sender: UIButton) {
        self.dismissExtraViews()
    }
    //Show extra view
    func showExtraViews(notification: NSNotification)  {
        let transform = CGAffineTransform.init(scaleX: 0.94, y: 0.94)
        self.topAnchorContraint.constant = 0
        self.darkView.isHidden = false
        if let type = notification.userInfo?["viewType"] as? ShowExtraView {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
                self.view.layoutIfNeeded()
                self.darkView.alpha = 0.8
                if (type == .contacts || type == .profile) {
                    self.view.transform = transform
                }
            })
            switch type {
            case .group:
                self.contactsView.isHidden = false
                closeBtn.isHidden = false
                TypeOfView = .group
                self.creationBtn.setTitle("New Group", for: .normal)
                runOnMainThread {
                    self.collectionView.reloadData()
                }
                //self.contactsView.
                if self.items.count == 0 {
                }
               // break
                
            case .contacts:
                TypeOfView = .contacts
              closeBtn.isHidden = true
                self.creationBtn.setTitle("Close", for: .normal)
                self.contactsView.isHidden = false
                runOnMainThread {
                    self.collectionView.reloadData()
                }
                if self.items.count == 0 {
                }
            case .profile:
                TypeOfView = .profile
                closeBtn.isHidden = true
                self.profileView.isHidden = false
            case .preview:
                TypeOfView = .preview
                closeBtn.isHidden = true
                self.previewView.isHidden = false
                self.previewImageView.image = notification.userInfo?["pic"] as? UIImage
                self.scrollView.contentSize = self.previewImageView.frame.size
            case .map:
                TypeOfView = .map
                closeBtn.isHidden = true
                self.mapPreviewView.isHidden = false
                let coordinate = notification.userInfo?["location"] as? CLLocationCoordinate2D
                let annotation = MKPointAnnotation.init()
                annotation.coordinate = coordinate!
                self.mapVIew.addAnnotation(annotation)
                self.mapVIew.showAnnotations(self.mapVIew.annotations, animated: false)
            }
        }
    }
    
    //Preview view scrollview's zoom calculation
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = self.previewImageView.frame.size.height / scale
        zoomRect.size.width  = self.previewImageView.frame.size.width  / scale
        let newCenter = self.previewImageView.convert(center, from: self.scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }
    
    //Downloads users list for Contacts View
    func fetchUsers()  {
        if let id = Auth.auth().currentUser?.uid {
            User.downloadAllUsers(exceptID: id, completion: {(user) in
                DispatchQueue.main.async {
                    self.items.append(user)
                    self.collectionView.reloadData()
                }
            })
        }
    }
    
    //Downloads current user credentials
    func fetchUserInfo() {
        if let id = Auth.auth().currentUser?.uid {
            User.info(forUserID: id, completion: {[weak weakSelf = self] (user) in
                DispatchQueue.main.async {
                    weakSelf?.nameLabel.text = user.name
                    weakSelf?.emailLabel.text = user.email
                    weakSelf?.profilePicView.image = user.profilePic
                    weakSelf = nil
                }
            })
        }
    }
    
    //Extra gesture to allow user double tap for zooming of preview view scrollview
    @IBAction func doubleTapGesture(_ sender: UITapGestureRecognizer) {
        if self.scrollView.zoomScale == 1 {
            self.scrollView.zoom(to: zoomRectForScale(scale: self.scrollView.maximumZoomScale, center: sender.location(in: sender.view)), animated: true)
        } else {
            self.scrollView.setZoomScale(1, animated: true)
        }
    }
    
    @IBAction func closeView(_ sender: Any) {
        if let sender = sender as? UIButton{
            if sender.titleLabel?.text == "New Group"{
                
                self.presentAlert()
                
            }else{
                self.dismissExtraViews()
            }
        }
        
    }
  
    func presentAlert() {
        let alertController = UIAlertController(title: "Name", message: "Type Group Name", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Confirm", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                // store your data
                
                 if let currentUserID = Auth.auth().currentUser?.uid {
                    var userIds = ""
                    for (index,element) in self.groupMemeber.enumerated(){
                        userIds = userIds + element.value + ","
                    }
                userIds = userIds + currentUserID  //String(userIds.characters.dropLast())
                    
                Group.createGroup(withName: field.text!, userIds: userIds, creatorID: currentUserID, completion: { flag,id,name in
                    
                    //if self.items.count > 0 {
                        self.dismissExtraViews()
                        if let ids = id{
                            let userInfo = ["groupID": ids,"groupName": field.text!]
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showUserMessages"), object: nil, userInfo: userInfo)

                            
                        }
                      //                    }
                    
                    self.groupMemeber.removeAll()
                    print("sucessfull")
                })
                }
                //groupMemeber
            
                self.dismissExtraViews()
            } else {
                // user did not fill field
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        
        self.dismissExtraViews()
        }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Name"
        }
        
        alertController.addAction(confirmAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func logOutUser(_ sender: Any) {
        User.logOutUser { (status) in
            if status == true {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    //MARK: Delegates
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.items.count == 0 {
            return 1
        } else {
            return self.items.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.items.count == 0 {
            let cell  = collectionView.dequeueReusableCell(withReuseIdentifier: "Empty Cell", for: indexPath)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! ContactsCVCell
            cell.profilePic.image = self.items[indexPath.row].profilePic
            cell.nameLabel.text = self.items[indexPath.row].name
            cell.profilePic.layer.borderWidth = 2
            cell.profilePic.layer.borderColor = GlobalVariables.purple.cgColor
            if let type = TypeOfView{
                switch type {
                case .group:
                    
                    cell.checkBox.on = false
                    cell.checkBox.tag = indexPath.item
                    cell.checkBox.isHidden = false
                    cell.checkBox.delegate = self
                    
                    break
                    
                case .contacts :
                    cell.checkBox.isHidden = true
                    break
                default:
                    cell.checkBox.isHidden = true
                    break
        }
            }
            //cell.checkBox.on = true
            return cell
        }
    }
    
    func didTap(_ checkBox: BEMCheckBox) {
         let tag = checkBox.tag
        if checkBox.on{
            groupMemeber.updateValue(self.items[tag].id, forKey: tag)
          
        }else{
              groupMemeber.removeValue(forKey: tag)
                   }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let type = TypeOfView{
            switch type {
            case .group:
                
                let cell = collectionView.cellForItem(at: indexPath) as! ContactsCVCell
                cell.checkBox.onAnimationType = .bounce
                cell.checkBox.setOn(true, animated: true)
                //cell
                
                 break
                
            case .contacts :
                    if self.items.count > 0 {
                        self.dismissExtraViews()
                        let userInfo = ["user": self.items[indexPath.row]]
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showUserMessages"), object: nil, userInfo: userInfo)
                }

                break
                
            default:
                break
                
            }
            
        }
        
          }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.items.count == 0 {
            return self.collectionView.bounds.size
        } else {
            if UIScreen.main.bounds.width > UIScreen.main.bounds.height {
                let width = (0.3 * UIScreen.main.bounds.height)
                let height = width + 30
                return CGSize.init(width: width, height: height)
            } else {
                let width = (0.3 * UIScreen.main.bounds.width)
                let height = width + 30
                return CGSize.init(width: width, height: height)
            }
        }
    }
    
    //Preview view scrollview zooming
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.previewImageView
    }

    //MARK: ViewController lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customization()        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.view.transform = CGAffineTransform.identity
    }    
}


