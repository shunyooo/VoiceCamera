//
//  ZUCameraViewController.swift
//  zeus
//
//  Created by student on 2016/10/22.
//  Copyright © 2016年 s.takagi. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreImage
import CoreMotion

class DefaultCameraViewController: BaseCameraViewController{
    
    var stillImageOutput: AVCapturePhotoOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stillImageOutput = AVCapturePhotoOutput()
        
        // 解像度の設定
        captureSesssion.sessionPreset = mySessionPreset
        
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            self.input = try AVCaptureDeviceInput(device: device)
            
            // 入力
            if (captureSesssion.canAddInput(input)) {
                captureSesssion.addInput(input)
                
                // 出力
                if (captureSesssion.canAddOutput(stillImageOutput)) {
                    captureSesssion.addOutput(stillImageOutput)
                    captureSesssion.startRunning() // カメラ起動
                    
                    previewLayer = AVCaptureVideoPreviewLayer(session: captureSesssion)
                    previewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
                    //AVLayerVideoGravityResizeAspect // アスクトフィット
                    previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait // カメラの向き
                    
                    cameraView.layer.addSublayer(previewLayer!)
                }
            }
        }
        catch {
            print(error)
        }
        
    }

    
    // ボタンを押した時呼ばれる
    @IBAction override func takeIt(_ sender: AnyObject) {
        // フラッシュとかカメラの細かな設定
        let settingsForMonitoring = AVCapturePhotoSettings()
        settingsForMonitoring.flashMode = flashMode
        settingsForMonitoring.isAutoStillImageStabilizationEnabled = true
        settingsForMonitoring.isHighResolutionPhotoEnabled = false
        // シャッターを切る
        stillImageOutput?.capturePhoto(with: settingsForMonitoring, delegate: self)
    }
    
    
    // デリゲート。カメラで撮影が完了した後呼ばれる。JPEG形式でフォトライブラリに保存。
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let photoSampleBuffer = photoSampleBuffer {
            // JPEG形式で画像データを取得
            let photoData = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: photoSampleBuffer, previewPhotoSampleBuffer: previewPhotoSampleBuffer)
            let image = UIImage(data: photoData!)
            let origin = image
            
            
            let or_image = UIImage(cgImage:origin!.cgImage!, scale: origin!.scale,orientation:self.orientation)
            
            //プレビュー画面へ。
            let storyboard: UIStoryboard = UIStoryboard(name: "PreviewImage", bundle: nil)
            let next: PreviewImageViewController = storyboard.instantiateInitialViewController() as! PreviewImageViewController
            next.sendImage = or_image
            present(next, animated: true, completion: nil)
        }
    }
    
    
}
