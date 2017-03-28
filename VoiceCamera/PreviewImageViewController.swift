//
//  ZUCameraPopViewController.swift
//  cam-2
//
//  Created by Syunyo Kawamoto on 2017/02/18.
//  Copyright © 2017年 Syunyo Kawamoto. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreImage
import CoreMotion

class PreviewImageViewController: UIViewController {

    @IBOutlet weak var ImageView: UIImageView!
    let albumName:String = "zeus"
    var sendImage:UIImage = UIImage(named:"btn")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ImageView.image = sendImage
        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBOutlet weak var cancelBtn: UIButton!
    @IBAction func cancelBtn(_ sender: Any) {
        //トップ画面に戻る。
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveBtn(_ sender: Any) {
        AlbumAccess.searchAndSavePhoto(ImageView.image!, albumName: self.albumName)
        self.dismiss(animated: false, completion: nil)
    }
}
