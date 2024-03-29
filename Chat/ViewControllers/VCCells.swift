//
//  SenderCell.swift
//  Chat
//
//  Created by Chitaranjan Sahu on 05/06/17.
//  Copyright © 2017 xelpmoc.in. All rights reserved.
//

import Foundation
import UIKit
import BEMCheckBox
import AVFoundation


class SenderCell: UITableViewCell {
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var messageBackground: UIImageView!
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var videoView: UIView!
    func clearCellData()  {
        self.message.text = nil
        self.message.isHidden = false
        self.messageBackground.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.message.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5)
        self.messageBackground.layer.cornerRadius = 15
        self.message.textColor = UIColor.black
        self.messageBackground.clipsToBounds = true
    }
    override func prepareForReuse() {
        self.playerLayer?.removeFromSuperlayer()
        self.player?.pause()
        
    }

}

class ReceiverCell: UITableViewCell {
    var playerLayer: AVPlayerLayer?
    var player: AVPlayer?
    @IBOutlet weak var message: UITextView!
    @IBOutlet weak var messageBackground: UIImageView!
    
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var videoView: UIView!
    func clearCellData()  {
        self.message.text = nil
        self.message.isHidden = false
        self.messageBackground.image = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        self.message.textContainerInset = UIEdgeInsetsMake(5, 5, 5, 5)
        self.message.textColor = UIColor.black
        self.messageBackground.layer.cornerRadius = 15
        self.messageBackground.clipsToBounds = true
    }
    
    override func prepareForReuse() {
        self.playerLayer?.removeFromSuperlayer()
        self.player?.pause()

    }
}

class ConversationsTBCell: UITableViewCell {
    
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    func clearCellData()  {
        self.nameLabel.font = UIFont(name:"AvenirNext-Regular", size: 17.0)
        self.messageLabel.font = UIFont(name:"AvenirNext-Regular", size: 14.0)
        self.timeLabel.font = UIFont(name:"AvenirNext-Regular", size: 13.0)
        self.profilePic.layer.borderColor = GlobalVariables.purple.cgColor
        self.messageLabel.textColor = UIColor.rbg(r: 111, g: 113, b: 121)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.profilePic.layer.borderWidth = 2
        self.profilePic.layer.borderColor = GlobalVariables.purple.cgColor
    }
    
}

class ContactsCVCell: UICollectionViewCell {
    
    @IBOutlet weak var profilePic: RoundedImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var checkBox: BEMCheckBox!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}




