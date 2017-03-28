//
//  AlbumAccess.swift
//  resizeSample
//
//  Created by Syunyo Kawamoto on 2017/03/20.
//  Copyright © 2017年 Syunyo Kawamoto. All rights reserved.

import UIKit
import Photos

class AlbumAccess: NSObject {
    
    //与えられた画像を、アルバムに保存。
    //アルバムが存在しない時は、アルバムを生成してから保存。
    public class func searchAndSavePhoto(_ img:UIImage,albumName:String){
        
        var theAlbum:PHAssetCollection? = searchAlbum(albumName)// アルバムをオブジェクト化
        
        //アルバムがなかった場合
        if theAlbum == nil{
            print("アルバムがなかったので、作成。")
            PHPhotoLibrary.shared().performChanges({ () -> Void in
                // iOSのフォトアルバムにコレクション(アルバム)を追加する.
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            }, completionHandler: { (isSuccess, error) -> Void in
                
                if isSuccess == true {
                    print("Success! Album:",albumName," is created.")
                    theAlbum = self.searchAlbum(albumName)
                    self.savePhoto(img,theAlbum:theAlbum!)
                }
                else{
                    print("error occured")
                }
                
            })
        }else{//アルバムがすでにあった場合
            //print("アルバムはすでにあったので、保存。")
            self.savePhoto(img,theAlbum: theAlbum!)
        }
    }
    
    //ZEUSアルバムを探す--> return
    public class func searchAlbum(_ albumName:String) -> PHAssetCollection? {
        //print("searchAlbum")
        var theAlbum:PHAssetCollection?
        
        let result = PHCollection.fetchTopLevelUserCollections(with: nil)
        
        print(result)
        
        result.enumerateObjects({(object, index, stop) in
            if let theCollection = object as? PHAssetCollection ,
                theCollection.localizedTitle == albumName
            {
                //print("Album:",albumName," is found.")
                theAlbum = theCollection            }
        })
        return theAlbum
    }
    
    //album-->写真を保存する。
    public class func savePhoto(_ savingImage:UIImage,theAlbum:PHAssetCollection){
        print("写真保存",savingImage.description)
        //print(cameraView.frame)
        
        //写真を保存
        PHPhotoLibrary.shared().performChanges({
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: savingImage)
            let assetPlaceholder = createAssetRequest.placeholderForCreatedAsset!
            let albumChangeRequest = PHAssetCollectionChangeRequest(for:theAlbum)
            albumChangeRequest!.addAssets([assetPlaceholder] as NSArray)
        }, completionHandler: nil)
    }
    
    public class func drawText(image :UIImage,text :String) ->UIImage
    {
        
        let font = UIFont.boldSystemFont(ofSize: 32)
        let imageRect = CGRect(x:0,y:0,width:image.size.width,height:image.size.height)
        
        UIGraphicsBeginImageContext(image.size);
        
        image.draw(in: imageRect)
        
        let textRect  = CGRect(x:5, y:5, width:image.size.width - 5, height:image.size.height - 5)
        let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let textFontAttributes = [
            NSFontAttributeName: font,
            NSForegroundColorAttributeName: UIColor.white,
            NSParagraphStyleAttributeName: textStyle
        ]
        text.draw(in: textRect, withAttributes: textFontAttributes)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext()
        
        return newImage!
    }

}
