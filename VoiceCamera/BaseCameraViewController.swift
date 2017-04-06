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
        
        //露出をロックする必要がない気がするので、やめた。
        //camera.addObserver(self, forKeyPath: "adjustingExposure", options: .new, context: nil)
        
        self.zoomSlider.isHidden = true
        self.zoomSlider.alpha = 0
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
        
        
        
        self.focusWithMode(focusMode: AVCaptureFocusMode.autoFocus, exposeWithMode: AVCaptureExposureMode.continuousAutoExposure, atDevicePoint: tapCGPoint, motiorSubjectAreaChange: true)
    }
    
    //露出が調整中かどうかを返す。
    var adjustingExposure = false
    
    
    func focusWithMode(focusMode : AVCaptureFocusMode, exposeWithMode expusureMode :AVCaptureExposureMode, atDevicePoint point:CGPoint, motiorSubjectAreaChange monitorSubjectAreaChange:Bool) {
        
        let pointOfInterest:CGPoint  = CGPoint(x:point.y / self.view.bounds.size.height,
                                               y:1.0 - point.x / self.view.bounds.size.width);
        
        let device : AVCaptureDevice = self.input.device
        print(point,pointOfInterest)
        
        do {
            try device.lockForConfiguration()
            if(device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode)){
                device.focusPointOfInterest = pointOfInterest
                device.focusMode = focusMode
                print("focus Mode:",device.focusMode.rawValue)
            }
            if(device.isExposurePointOfInterestSupported && device.isExposureModeSupported(expusureMode)){
                adjustingExposure = true
                device.exposurePointOfInterest = pointOfInterest
                device.exposureMode = expusureMode
                print("exposure Mode:",device.exposureMode.rawValue)
            }
            
            device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
            device.unlockForConfiguration()
            
        } catch let error as NSError {
            print(error.debugDescription)
        }
    }
    
    
    //viewDidloadのaddobseverで登録できるが、露出を固定する必要はないので、やめた。
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("forKeyPath:",keyPath ?? "nil")
        
        //露出が調整中じゃない時は処理を返す
        if (!self.adjustingExposure) {
            return
        }
        //露出の情報
        if keyPath == "adjustingExposure" {
            let isNew = change?[NSKeyValueChangeKey.newKey]
            if (isNew != nil) {
                //露出が決定した
                self.adjustingExposure = false
                //露出を固定する
                let camera: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
                do {
                    try camera.lockForConfiguration()
                    print("locked Exprosure")
                    camera.exposureMode = AVCaptureExposureMode.locked
                    camera.unlockForConfiguration()
                } catch {
                    //
                }
            }
        }
    }
    
    var pinchState:UIGestureRecognizerState = .ended
    var pinchId:Int = 0
    
    func pinchedGesture(gestureRecgnizer: UIPinchGestureRecognizer) {
        do {
            try camera.lockForConfiguration()
            self.pinchState = gestureRecgnizer.state
            
            print(checkState(self.pinchState))
            
            // スライドバーがクリアされていて、初めてタッチされた時、表示。
            if pinchState == .began && pinchId == 0{
                
                print("animate appear")
                self.zoomSlider.isHidden = false
                UIView.animate(withDuration: 0.1, animations: {
                    self.zoomSlider.alpha = 1
                }, completion: { finished in
                })
            }
            
            // スライドバーが消えるアニメーション中にピンチしてしまった場合のため
            self.zoomSlider.isHidden = false
            
            
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
                self.pinchState = gestureRecgnizer.state
                self.pinchId += 1
                //何秒か後に消す。
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.pinchId -= 1
                    print("gestureRecgnizer.id",self.pinchId)
                    
                    // pinchIdが0は、最後に触られたことを示す。
                    if self.pinchState == .ended && self.pinchId == 0{
                        UIView.animate(withDuration: 1, animations: {
                            self.zoomSlider.alpha = 0
                        }, completion: { finished in
                            self.zoomSlider.isHidden = true
                        })
                    }
                }
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
    
    func checkState(_ state:UIGestureRecognizerState) -> String{
        switch state {
        case .possible:
            return "possible"
        case .began:
            return "began"
        case .cancelled:
            return "cancelled"
        case .changed:
            return "changed"
        case .ended:
            return "ended"
        case .failed:
            return "failed"
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
    @IBOutlet weak var actionSettingButton: UIButton!
    
    @IBAction func actionSettingButton(_ sender: Any) {
        //設定画面へ
        let storyboard: UIStoryboard = UIStoryboard(name: "Setting", bundle: nil)
        let nextView =  storyboard.instantiateInitialViewController()
        nextView?.modalTransitionStyle = .flipHorizontal
        self.present(nextView!, animated: true, completion: nil)

    }
    
    @IBAction func actionBackButton(_ sender: AnyObject) {
        //トップ画面に戻る。
        self.dismiss(animated: true, completion: nil)
        motionManager.stopAccelerometerUpdates()
    }
}
