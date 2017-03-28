//
//  BaseCameraViewController.swift
//  CamTest
//
//  Created by Syunyo Kawamoto on 2017/03/27.
//  Copyright © 2017年 Syunyo Kawamoto. All rights reserved.
//

import UIKit
import AVFoundation
import Photos
import CoreImage
import CoreMotion

//カメラクラスの基底クラスとなる。共通機能などを実装。
class BaseCameraViewController: UIViewController ,AVCapturePhotoCaptureDelegate, UIGestureRecognizerDelegate{

    
    //解像度選択
    let mySessionPreset:String = AVCaptureSessionPresetPhoto
    //以下候補から選択してください
    //AVCaptureSessionPreset352x288
    //AVCaptureSessionPreset640x480
    //AVCaptureSessionPresetiFrame960x540
    //AVCaptureSessionPresetiFrame1280x720
    //AVCaptureSessionPreset1280x720
    //AVCaptureSessionPreset1920x1080
    //AVCaptureSessionPreset3840x2160
    
    
    // カメラの映像をここに表示
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var icon: UIImageView!
    
    var camera:AVCaptureDevice!
    
    var captureSesssion: AVCaptureSession!
    //var stillImageOutput: AVCapturePhotoOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var input:AVCaptureDeviceInput!
    
    // アルバム名を保存するtext.
    var albumName : String! = "zeus"
    
    var orientation:UIImageOrientation = .right
    
    //motionManager
    var motionManager:CMMotionManager!
    var pre_rotate:Double = 0
    
    var oldZoomScale: CGFloat = 1.0
    
    
    var flashMode:AVCaptureFlashMode! = .off
    
    @IBOutlet weak var flashModeBtn: UIButton!
    
    @IBAction func flashModeBtn(_ sender: Any) {
        if flashMode == .off{
            flashMode = .on
            flashModeBtn.setImage(UIImage(named:"flash-on"), for: .normal)
        }else{
            flashMode = .off
            flashModeBtn.setImage(UIImage(named:"flash-off"), for: .normal)
        }
    }
    
    
    // ボタンを押した時呼ばれる
    @IBAction func takeIt(_ sender: AnyObject) {
    }
    
    
    override func viewDidLoad() {
        
        // モーション系の初期化
        self.initMotionManager()
        
        // Viewにタップ、ピンチのジェスチャーを追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tappedScreen(gestureRecognizer:)))
        tapGesture.delegate = self
        self.view.addGestureRecognizer(tapGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchedGesture(gestureRecgnizer:)))
        self.view.addGestureRecognizer(pinchGesture)
        
        
        captureSesssion = AVCaptureSession()
        camera = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera,
                                               mediaType: AVMediaTypeVideo,
                                               position: .back)
    }
    
    // モーション系の初期化
    func initMotionManager(){
        // 加速度を測定することにより、ロック中にも画面の向きに対応できるように。
        motionManager = CMMotionManager()
        motionManager.accelerometerUpdateInterval = 0.1
        // 加速度の取得を開始.
        motionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: {(accelerometerData, error) in
            if let e = error {
                print(e.localizedDescription)
                return
            }
            guard let data = accelerometerData else {
                return
            }
            
            let x = data.acceleration.x
            let y = data.acceleration.y
            var rotate:Double = 0
            
            if x*x > y*y{
                if x > 0{
                    rotate = -90
                    self.orientation = .down
                }
                if x < 0{
                    rotate = 90
                    self.orientation = .up
                }
            }else{
                if y > 0{
                    rotate = 180
                    self.orientation = .left
                }
                if y < 0{
                    rotate = 0
                    self.orientation = .right
                }
            }
            
            if rotate != self.pre_rotate{
                self.pre_rotate = rotate
                let angleRad:CGFloat = CGFloat((rotate*M_PI)/180)
                
                UIView.animate(withDuration: 1.0,
                               // 遅延時間.
                    delay: 0.0,
                    // バネの弾性力. 小さいほど弾性力は大きくなる.
                    usingSpringWithDamping: 0.9,
                    // 初速度.
                    initialSpringVelocity: 1,
                    // 一定の速度.
                    options: UIViewAnimationOptions.curveLinear,
                    animations: { () -> Void in
                        // 回転用のアフィン行列を生成.
                        self.icon.transform = CGAffineTransform(rotationAngle: angleRad)
                },
                    completion: { (Bool) -> Void in
                })
            }
        })
        
        //ズーム系の設定
        zoomSlider.maximumValue = 6.0
        zoomSlider.minimumValue = 1.0
    }
    
    //after view draw 画面の大きさ取得用
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // ビューのサイズの調整
        previewLayer?.position = CGPoint(x: self.cameraView.bounds.width / 2, y: self.cameraView.bounds.height / 2)
        previewLayer?.bounds = self.cameraView.bounds
        previewLayer?.layoutIfNeeded()
    }
    
    //画面タップでフォーカス
    let focusView = UIView()
    func tappedScreen(gestureRecognizer: UITapGestureRecognizer) {
        let tapCGPoint = gestureRecognizer.location(ofTouch: 0, in: gestureRecognizer.view)
        focusView.frame.size = CGSize(width: 170, height: 170)
        focusView.center = tapCGPoint
        focusView.backgroundColor = UIColor.white.withAlphaComponent(0)
        focusView.layer.borderColor = UIColor.white.cgColor
        focusView.layer.borderWidth = 2
        focusView.alpha = 1
        self.view.addSubview(focusView)
        
        
        
        UIView.animate(withDuration: 0.3,delay: 0.0,
                       usingSpringWithDamping: 0.9,
                       // 初速度.
            initialSpringVelocity: 1,
            // 一定の速度.
            options: UIViewAnimationOptions.curveLinear,
            animations: {
                self.focusView.frame.size = CGSize(width: 80, height: 80)
                self.focusView.center = tapCGPoint
        }, completion: { Void in
            UIView.animate(withDuration: 0.5, animations: {
                self.focusView.alpha = CGFloat(0)
            })
        })
        
        
        
        self.focusWithMode(focusMode: AVCaptureFocusMode.autoFocus, exposeWithMode: AVCaptureExposureMode.autoExpose, atDevicePoint: tapCGPoint, motiorSubjectAreaChange: true)
    }
    
    
    
    
    func focusWithMode(focusMode : AVCaptureFocusMode, exposeWithMode expusureMode :AVCaptureExposureMode, atDevicePoint point:CGPoint, motiorSubjectAreaChange monitorSubjectAreaChange:Bool) {
        
        let device : AVCaptureDevice = self.input.device
        print(point)
        
        do {
            try device.lockForConfiguration()
            if(device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode)){
                device.focusPointOfInterest = point
                device.focusMode = focusMode
            }
            if(device.isExposurePointOfInterestSupported && device.isExposureModeSupported(expusureMode)){
                device.exposurePointOfInterest = point
                device.exposureMode = expusureMode
            }
            
            device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
            device.unlockForConfiguration()
            
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    
    
    
    func pinchedGesture(gestureRecgnizer: UIPinchGestureRecognizer) {
        do {
            try camera.lockForConfiguration()
            // ズームの最大値
            let maxZoomScale: CGFloat = 6.0
            // ズームの最小値
            let minZoomScale: CGFloat = 1.0
            // 現在のカメラのズーム度
            var currentZoomScale: CGFloat = camera.videoZoomFactor
            // ピンチの度合い
            let pinchZoomScale: CGFloat = gestureRecgnizer.scale
            
            // ピンチアウトの時、前回のズームに今回のズーム-1を指定
            // 例: 前回3.0, 今回1.2のとき、currentZoomScale=3.2
            if pinchZoomScale > 1.0 {
                currentZoomScale = oldZoomScale+pinchZoomScale-1
            } else {
                currentZoomScale = oldZoomScale-(1-pinchZoomScale)*oldZoomScale
            }
            
            // 最小値より小さく、最大値より大きくならないようにする
            if currentZoomScale < minZoomScale {
                currentZoomScale = minZoomScale
            }
            else if currentZoomScale > maxZoomScale {
                currentZoomScale = maxZoomScale
            }
            
            // 画面から指が離れたとき、stateがEndedになる。
            if gestureRecgnizer.state == .ended {
                oldZoomScale = currentZoomScale
            }
            
            camera.videoZoomFactor = currentZoomScale
            print(currentZoomScale)
            zoomSlider.value = Float(currentZoomScale)
            
            camera.unlockForConfiguration()
        } catch {
            // handle error
            return
        }
    }

    @IBOutlet weak var zoomSlider: UISlider!
    @IBAction func zoomSlider(_ sender: UISlider) {
        do {
            try camera.lockForConfiguration()
            camera.videoZoomFactor = CGFloat(sender.value)
            camera.unlockForConfiguration()
        }catch{
            print("error")
        }
    }
    
    
    @IBAction func actionBackButton(_ sender: AnyObject) {
        //トップ画面に戻る。
        self.dismiss(animated: true, completion: nil)
        motionManager.stopAccelerometerUpdates()
    }
}
