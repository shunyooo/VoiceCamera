//
//  ConfigViewController.swift
//  CamTest
//
//  Created by Syunyo Kawamoto on 2017/03/30.
//  Copyright © 2017年 Syunyo Kawamoto. All rights reserved.
//

import UIKit
import Eureka

class SettingViewController: FormViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ getSection(title: "シャッター", forKey: "Shutter")
             //+++ getSection(title: "ズーム", forKey: "Zoom")
             //+++ getSection(title: "フラッシュ", forKey: "Flash")
             //+++ getSection(title: "トーチ", forKey: "Torch")
    }
    
    func getSection(title:String,forKey:String)->Section{
        return MultivaluedSection(multivaluedOptions: [.Insert],
                           header: title
        ) {
            $0.addButtonProvider = { section in
                return ButtonRow(){
                    $0.title = "Add"
                }
            }
            $0.multivaluedRowToInsertAt = { index in
                print("multivaluedRowToInsertAt",index)
                return self.getTextRow(title: title, forKey: forKey, index: index)
            }
            $0 <<< self.getTextRow(title: title, forKey: forKey, index: 0)
        }

    }
    
    func getTextRow(title:String,forKey:String,index:Int)->TextRow{

        let userDefault = UserDefaults.standard
        
        let row = TextRow("") { row in
                row.tag = forKey+String(index)
                if var shutters:[String] = userDefault.object(forKey: forKey) as? [String]{
                    row.title = title
                    if shutters.count > index{
                        row.placeholder = shutters[index]
                    }else{
                        row.placeholder = "やっほー"
                        shutters.append(row.value!)
                        userDefault.setValue(shutters, forKey: forKey)
                    }
                }else{
                    row.title = title
                    row.placeholder = "やっほー"
            }
            }.onChange{row in
                if var shutters:[String] = userDefault.object(forKey: forKey) as? [String]{
                    if shutters.count > index{
                        shutters[index] = row.value!
                    }else{
                        shutters.append(row.value!)
                    }
                    userDefault.setValue(shutters, forKey: forKey)
                }else{
                    userDefault.setValue([row.value], forKey: forKey)
                }
                //row.updateCell()
            }.cellSetup { cell, row in
                //cell.backgroundColor = .lightGray
            }.cellUpdate { cell, row in
                //cell.textLabel?.font = .italicSystemFont(ofSize: 18.0)
        }
        
        return row
    }
    
    
    
    @IBAction func actionBackButton(_ sender: AnyObject) {
        //トップ画面に戻る。
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
