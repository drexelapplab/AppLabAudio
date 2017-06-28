import UIKit
import AVFoundation
import AudioUnit
import CoreAudioKit
import XCPlayground
import PlaygroundSupport

public class AppLabAudioKit: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    @available (iOS 2.0, *)
    public func numberOfComponents (in pickerView: UIPickerView) -> Int {
        return 1 
    }
    var cover:UIView?
    var playButton:UIButton?
    var pauseButton:UIButton?
    var menu:UIPickerView?
    var view:UIView?

    var pitchEngine:AppLabPitchEngine?
    var waveform:AppLabWaveForm?
    
    var audioSession:AVAudioSession?
    var sampler:AVAudioUnitSampler?
    var distortion:AVAudioUnitDistortion?
    var reverb:AVAudioUnitReverb?
    var pitch:AVAudioUnitTimePitch?
    var audioPlayer:AVAudioPlayerNode?
    var buffer:AVAudioPCMBuffer?
    var engine:AVAudioEngine?
    
    public var engineIsCreated:Bool
    public var isPaused:Bool
    
    open var Songs:[(String,URL)]
    open var pickerData:[String]
    open var selected:String
    
    public init (view:UIView) {
        PlaygroundPage.current.needsIndefiniteExecution = true
        audioSession = AVAudioSession.sharedInstance ()
        pitchEngine = AppLabPitchEngine ()
        self.view = view
        engineIsCreated = false
        isPaused = false
        Songs = Bundle.main.urls (forResourcesWithExtension: ".m4a", subdirectory: "")!.map ({
            return ($0.pathComponents.last!.replacingOccurrences (of: ".m4a", with: "")
                , $0)
        })
        self.selected = Songs.first!.0
        pickerData = Songs.map ({$0.0})
        super.init ()
        do {
            try audioSession?.setCategory (AVAudioSessionCategoryPlayAndRecord)
            try audioSession?.setActive (true)
            print ("AudioSession Created")
            self.loadPlayUI ()
            print ("UI Loaded")
            engine = AVAudioEngine ()
            engine?.attach (sampler!)
            engine?.attach (distortion!)
            engine?.attach (reverb!)
            engine?.attach (audioPlayer!)
            print ("Engine Setup")
        } catch {
            print ("failed to initialize audio session")
        }
    }
    
    func loadPlayUI() {
        print ("UI Loading")
        playButton = UIButton (frame: CGRect(x: 250, y: 30, width: 128, height: 64))
        playButton?.setTitle ("play", for: .normal)
        playButton?.titleLabel?.font = UIFont.preferredFont (forTextStyle: .title1)
        playButton?.addTarget (self, action: #selector(playToggle), for: .                touchUpInside)
        playButton?.backgroundColor = UIColor.black
        view?.addSubview (playButton!)
        menu = UIPickerView (frame: CGRect (x: 250, y: 100, width: 125, height: 250))
        menu?.delegate = self
        menu?.dataSource = self
        view?.addSubview (menu!)
        print ("creating AVAudio Nodes")
        audioPlayer = AVAudioPlayerNode ()
        sampler = AVAudioUnitSampler ()
        distortion = AVAudioUnitDistortion ()
        reverb = AVAudioUnitReverb ()
        buffer = nil
    }
    
    func connectNodes () {
        if self.engineIsCreated { return }
        print ("connecting nodes")
        let node = engine?.mainMixerNode
        let format = AVAudioFormat (standardFormatWithSampleRate: 44100.0, channels: 2)
        let pformat = buffer?.format
        engine?.connect (audioPlayer!, to: reverb!, format: pformat)
        engine?.connect (reverb!, to: node!, fromBus: 0, toBus: 0, format: pformat)
        engine?.connect (distortion!, to: node!, fromBus: 0, toBus: 2, format: format)
        let dNodes = [AVAudioConnectionPoint (node: (engine?.mainMixerNode)!, bus:1), AVAudioConnectionPoint (node:distortion!, bus:0)]
        engine?.connect (sampler!, to: dNodes, fromBus: 0, format: format)
        print ("nodes connected")
        self.engineTap ()
        self.engineIsCreated = true
    }
    
    func engineTap () {
        print ("tapping engine")
        audioPlayer?.installTap (onBus: 0, bufferSize: 22050, format: buffer?.format, block: {buff, time in
            DispatchQueue.main.async {
                self.pitchEngine?.pitch (from: buff, withRate: (self.buffer?.format.sampleRate)!)
            }
        })
    }
    
    func getSongTime () -> TimeInterval {
        let nsamples = buffer?.frameLength
        let time = Double (nsamples!) / (buffer?.format.sampleRate)!
        return time
    }
    
    func play () {
        if (waveform != nil) {
            waveform?.removeFromSuperview ()
        }
        if (cover != nil) {
            cover?.removeFromSuperview ()
        }
        if (audioPlayer?.isPlaying)! {
            audioPlayer?.stop ()
        }
        let source = Songs[(menu?.selectedRow (inComponent: 0))!].1
        print ("loading song")
        let file = try! AVAudioFile (forReading: source)
        let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
        try! file.read (into: buffer!)
        print ("file loaded into buffer")
        if !self.engineIsCreated { self.connectNodes () }
        
        print ("buffer setup on player")
        buildWaveForm (from: source)
        print ("waveform loaded")
        
        UIView.animate (withDuration: getSongTime (), delay: 0.0, options: [.curveLinear], animations: {
            self.cover?.frame = CGRect (x: (self.view?.frame.width)!, y: 300, width: 0, height: 200)
        })
        print ("starting engine")
        if !(engine?.isRunning)! { try! engine?.start () }
        print ("playing song")
        engine?.prepare ()
        
        audioPlayer?.prepare (withFrameCount: (buffer?.frameLength)!)
        audioPlayer?.play ()
        audioPlayer?.scheduleBuffer (buffer!, at: nil, completionHandler: nil)
    }
    
    @objc func playToggle () {
        if (audioPlayer != nil) {
            if selected != Songs[(menu?.selectedRow (inComponent: 0))!].0 {
                selected = Songs[(menu?.selectedRow (inComponent: 0))!].0
                self.play ()
            } else if (audioPlayer?.isPlaying)! {
                let pausedTime: CFTimeInterval = (cover?.layer.convertTime (CACurrentMediaTime (), from: nil))!
                cover?.layer.speed = 0.0
                cover?.layer.timeOffset = pausedTime
                audioPlayer?.pause ()
                self.isPaused = true
            } else if isPaused {
                let pausedTime: CFTimeInterval = (cover?.layer.timeOffset)!
                    cover?.layer.speed = 1.0
                    cover?.layer.timeOffset = 0.0
                    cover?.layer.beginTime = 0.0
                    let timeSincePause: CFTimeInterval = (cover?.layer.convertTime (CACurrentMediaTime (), from: nil))! - pausedTime
                    cover?.layer.beginTime = timeSincePause
                    self.isPaused = false
                    audioPlayer?.play ()
            } else {
                    self.play ()
            }
        }
    }
    
    func buildWaveForm (from source: URL) {
        waveform = AppLabWaveForm (audio: source, frm: CGRect (x: 0, y: 300, width: (view?.frame.width)!, height: 200))
        cover = UIView (frame: CGRect (x: 0, y: 300, width: (view?.frame.width)!, height: 200))
        cover?.backgroundColor = UIColor.black
        cover?.alpha = 0.5
        cover?.layer.opacity = 0.5
        cover?.layer.isOpaque = true
        view?.addSubview (waveform!)
        view?.addSubview (cover!)
        view?.bringSubview (toFront: cover!)
    }
    
    public func pickerView (_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    public func numberOfComponentsInPickerView (pickerView: UIPickerView) -> Int {
        return 1
    }
    public func pickerView (_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
}


