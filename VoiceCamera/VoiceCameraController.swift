//
//  VoiceCameraController.swift
//  VoiceCamera
//
//  Created by Syunyo Kawamoto on 2017/03/29.
//  Copyright © 2017年 Syunyo Kawamoto. All rights reserved.
//

import UIKit
import Speech
import AVFoundation

// シャッター系の機能は DefaultCameraViewController　で実装。
class VoiceCameraController: DefaultCameraViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var recIndicator: UIActivityIndicatorView!
    
    // "ja-JP"を指定すると日本語になります。
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))!
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        recIndicator.isHidden = true
        recIndicator.stopAnimating()
        
        statusLabel.isHidden = true
        
        requestRecognizerAuthorization()
    }
    
    private func requestRecognizerAuthorization() {
        // 認証処理
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // メインスレッドで処理したい内容のため、OperationQueue.main.addOperationを使う
            OperationQueue.main.addOperation { [weak self] in
                guard let `self` = self else { return }
                
                switch authStatus {
                case .authorized:
                    self.voiceButton.isEnabled = true
                    
                case .denied:
                    self.voiceButton.isEnabled = false
                    self.alert(title: "エラー", message: "音声認識へのアクセスが拒否されています。")
                    
                case .restricted:
                    self.voiceButton.isEnabled = false
                    self.alert(title: "エラー", message: "この端末で音声認識はできません。")
                    
                case .notDetermined:
                    self.voiceButton.isEnabled = false
                    self.alert(title: "エラー", message: "音声認識はまだ許可されていません。")
                }
            }
        }
    }
    
    private func startRecording() throws {
        refreshTask()
        
        let audioSession = AVAudioSession.sharedInstance()
        // 録音用のカテゴリをセット
        try audioSession.setCategory(AVAudioSessionCategoryRecord)
        try audioSession.setMode(AVAudioSessionModeMeasurement)
        try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else { fatalError("Audio engine has no input node") }
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to created a SFSpeechAudioBufferRecognitionRequest object") }
        
        // 録音が完了する前のリクエストを作るかどうかのフラグ。
        // trueだと現在-1回目のリクエスト結果が返ってくる模様。falseだとボタンをオフにしたときに音声認識の結果が返ってくる設定。
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let `self` = self else { return }
            
            var isFinal = false
            
            if let result = result {
                self.label.text = result.bestTranscription.formattedString
                isFinal = result.isFinal
            }
            
            // エラーがある、もしくは最後の認識結果だった場合の処理
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.voiceButton.isEnabled = true
                //self.button.setTitle("音声認識スタート", for: [])
                self.statusLabel.text = "音声認識スタート"
            }
        }
        
        // マイクから取得した音声バッファをリクエストに渡す
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            self.recognitionRequest?.append(buffer)
        }
        
        try startAudioEngine()
    }
    
    private func refreshTask() {
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }
    }
    
    private func startAudioEngine() throws {
        // startの前にリソースを確保しておく。
        audioEngine.prepare()
        
        try audioEngine.start()
        
        label.text = "音声認識中.."
        
    }
    
    
    @IBOutlet weak var voiceButton: UIButton!
    @IBAction func VoiceButton(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            voiceButton.isEnabled = false
            statusLabel.text = "停止中"
            recIndicator.stopAnimating()
            recIndicator.isHidden = true
        } else {
            try! startRecording()
            statusLabel.text = "音声認識を中止"
            recIndicator.isHidden = false
            recIndicator.startAnimating()
        }
    }
    
    
    func alert(title:String,message:String){
        // アラート表示
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            print("OKボタン押下")
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }

}


extension VoiceCameraController: SFSpeechRecognizerDelegate {
    // 音声認識の可否が変更したときに呼ばれるdelegate
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            voiceButton.isEnabled = true
            //button.setTitle("音声認識スタート", for: [])
            statusLabel.text = "音声認識スタート"
        } else {
            voiceButton.isEnabled = false
            //button.setTitle("音声認識ストップ", for: .disabled)
            statusLabel.text = "音声認識ストップ"
        }
    }
}
