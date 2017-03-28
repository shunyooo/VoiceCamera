//
//  ViewController.swift
//  VoiceCamera
//
//  Created by Syunyo Kawamoto on 2017/03/29.
//  Copyright © 2017年 Syunyo Kawamoto. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //カメラ画面へ。
        let storyboard: UIStoryboard = UIStoryboard(name: "VoiceCamera", bundle: nil)
        let next = storyboard.instantiateInitialViewController()
        present(next!, animated: false, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

