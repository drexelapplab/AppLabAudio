import UIKit
import AVFoundation
import AudioUnit
import CoreAudioKit
import PlaygroundSupport

public class AppLabAudioController:NSObject, AVAudioRecorderDelegate {
    //visual elements section
    var playButton: UIView?
    var noteView: UIView?
    var view: UIView?
    var cover: UIView?
    //audio source|also used as flag for audio init
    var source: URL?
    var recorded: URL?
    //engines and other applab classes
    var waveform: AppLabWaveForm?
    var pitchEngine: AppLabPitchEngine?
    //apple's audio engine modules
    var audioSession:AVAudioSession?
    var recorder:AVAudioRecorder?
    var sampler:AVAudioUnitSampler?
    var distorter:AVAudioUnitDistortion?
    var reverber:AVAudioUnitReverb?
    var audioPlayer:AVAudioPlayerNode?
    var buffer:AVAudioPCMBuffer?
    var engine:AVAudioEngine?
    //control flags
    var isPaused:Bool
    var hasPlayed:Bool
    var hasWaveForm:Bool
    //errors
    enum AppLabAudioControllerErrors: Error {
        case FloatChannelDataIsNil
    }
    //least intensive init, needs audio source to still be set before it can do anything
    public init (_ page: UIView) {
        hasPlayed = false
        isPaused = true
        hasWaveForm = false
        PlaygroundPage.current.needsIndefiniteExecution = true//allow threading
        audioSession = AVAudioSession.sharedInstance ()
        view = page
        source = nil
        super.init ()
        do {//setup audio settings
            try audioSession?.setCategory (AVAudioSessionCategoryPlayAndRecord)
            try audioSession?.setActive (true)
            //create engine modules
            self.loadEngineModules ()
            //create engine
            engine = AVAudioEngine ()
            //build engine
            engine?.attach (sampler!)
            engine?.attach (distorter!)
            engine?.attach (reverber!)
            engine?.attach (audioPlayer!)
            //create connects internal to the engine
            self.connectEngineModules ()
            
            self.loadUI ()
        } catch {
            //uhoh
            print ("Error creating Audio Session!")
        }
    }
    //init that loads the {audio} files into the buffer
    public init (_ page: UIView, withSource audio: String) {
        hasPlayed = false
        isPaused = true
        hasWaveForm = false
        PlaygroundPage.current.needsIndefiniteExecution = true
        audioSession = AVAudioSession.sharedInstance ()
        view = page
        source = Bundle.main.url (forResource: audio, withExtension: ".m4a")
        super.init ()
        do {//setup audio settings
            try audioSession?.setCategory (AVAudioSessionCategoryPlayAndRecord)
            try audioSession?.setActive (true)
            //create engine modules
            self.loadEngineModules ()
            //create engine
            engine = AVAudioEngine ()
            //build engine
            engine?.attach (sampler!)
            engine?.attach (distorter!)
            engine?.attach (reverber!)
            engine?.attach (audioPlayer!)
            //create connects internal to the engine
            self.connectEngineModules ()
            //attempt to load audio file into buffer
            let file = try! AVAudioFile (forReading: source!)
            let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
            buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
            try! file.read (into: buffer!)
            //prepare engine to play
            engine?.prepare ()
            audioPlayer?.prepare (withFrameCount: (buffer?.frameLength)!)

            self.loadUI ()
        } catch {
            print ("Error creating Audio Session!")
        }
    }
    
    public func loadAudio (_ audio: String) {
        /*
         this function attempts to load the file with the name {audio} into the buffer. 
         it will crash if the function is not inside the buffer.
        */
        source = Bundle.main.url (forResource: audio, withExtension: ".m4a")
        let file = try! AVAudioFile (forReading: source!)
        let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
        try! file.read (into: buffer!)
    }
    
    public func showNotes () {
        /*
         this function will install the PitchEngine onto the buffer.
        */
        if source == nil {
            print ("no audio loaded")
        } else {
            if pitchEngine == nil {
                pitchEngine = AppLabPitchEngine ()
            }
            //uses threading to ensure the installed operation does not mess with playback or mainthread.
            audioPlayer?.installTap (onBus: 0,
                                     bufferSize: 11025,
                                     format: buffer?.format,
                                     block:{buff, time in
                DispatchQueue.main.async {
                    self.pitchEngine?.pitch (from: buff,
                        withRate: (self.buffer?.format.sampleRate)!)
                }
            })
        }
    }
    
    public func showWaveForm () {
        /*
         this function will setup the AppLabWaveForm to display the current buffer. 
         It will also setup the cover UIView which is used in animating during playback.
         */
        if source == nil {
            print ("no audio loaded")
        } else {
            waveform = AppLabWaveForm (buffer: buffer!,
                                       frm: CGRect (x: (view?.frame.minX)!,
                                                    y: (view?.frame.maxY)!-400,
                                                    width: (view?.frame.width)!,
                                                    height: 400))
            cover = UIView (frame: CGRect (x: (view?.frame.minX)!,
                                           y: (view?.frame.maxY)!-400,
                                           width: (view?.frame.width)!,
                                           height: 400))
            //display settings for the cover along with adding them to view
            cover?.backgroundColor = UIColor.black
            cover?.alpha = 0.5
            cover?.layer.opacity = 0.5
            cover?.layer.isOpaque = true
            view?.addSubview (waveform!)
            view?.addSubview (cover!)
            view?.bringSubview (toFront: cover!)
        }
        hasWaveForm = true
    }
    
    func getAudioTime () -> TimeInterval {
        /*
         this function will return the time it takes to play the curent buffer.
        */
        if source == nil {
            print ("no audio loaded")
            return 0
        } else {
            let nsamples = buffer?.frameLength
            return Double (nsamples!) / (buffer?.format.sampleRate)!
        }
    }
    
    public func tapAudio (withBlock:@escaping (AVAudioPCMBuffer, Double) -> Void, onChunksOfSize size: Int) {
        /*
         this function will install the {withBlock} function onto the audio output buffer. 
         It is meant to allow users to process chunks of the audio during playback.
        */
        if source == nil {
            print ("no audio loaded")
        } else {
            //uses threading to ensure the installed operation does not mess with playback or mainthread.
            audioPlayer?.installTap (onBus: 0,
                                     bufferSize: AVAudioFrameCount(size),
                                     format: buffer?.format,
                                     block:{buff, time in
                DispatchQueue.main.async {
                    withBlock (buff, (self.buffer?.format.sampleRate)!)
                }
            })
        }
    }
    
    public func add (distortion: Float) {
        /*
         adds distortion to the engine
        */
        if source == nil {
            print ("no audio loaded")
        } else {
            self.distorter?.wetDryMix = distortion
        }
    }
    
    public func add (reverb: Float) {
        /*
         adds reverb to the engine
         */
        
        if source == nil {
            print ("no audio loaded")
        } else {
            self.reverber?.wetDryMix = reverb
        }
    }
    
    public func add (timeScale: Float) {
        /*
         changes the rate of the output buffer.
         */
        if source == nil {
            print ("no audio loaded")
        } else {
            self.audioPlayer?.rate = timeScale
        }
    }
    
    func loadEngineModules () {
        /*
         this function creates all of the AVAudioUnits using during the engine. 
         they are made in a different function from the connection/attachment processes to ensure variable longevity.
        */
        print ("<creating Audio Engine Modules>")
        audioPlayer = AVAudioPlayerNode ()
        sampler = AVAudioUnitSampler ()
        distorter = AVAudioUnitDistortion ()
        reverber = AVAudioUnitReverb ()
        buffer = nil
    }
    
    func connectEngineModules () {
        /*
         this function sets up all of the internal connects in the AudioEngine.
         -------------------------------ENGINE-------------------------------
         *                                                                  *
         *         audioBuffer------->audioPlayer                           *
         *                               /                                  *
         *                              /            Sampler                *
         *                             /                |                   *
         *                            /                 |                   *
         *                      Reverber----Distorter------->ouput          *
         *                                                                  *
         --------------------------------------------------------------------
        */
        print ("<connecting Audio Engine Modules>")
        let node = engine?.mainMixerNode
        let format = AVAudioFormat (standardFormatWithSampleRate: 44100.0, channels: 2)
        let pformat = buffer?.format
        engine?.connect (audioPlayer!, to: reverber!, format: pformat)
        engine?.connect (reverber!, to: node!, fromBus: 0, toBus: 0, format: pformat)
        engine?.connect (distorter!, to: node!, fromBus: 0, toBus: 2, format: format)
        let dNodes = [AVAudioConnectionPoint (node: (engine?.mainMixerNode)!, bus:1),
                      AVAudioConnectionPoint (node:distorter!, bus:0)]
        engine?.connect (sampler!, to: dNodes, fromBus: 0, format: format)
    }
    
    func loadUI () {
        //@todo
    }
    
    @objc func playpause () {
        /*
         this function toggles play/pause. It can be attached to a UIGestureRecognizer.
        */
        if source == nil {
            print ("no audio loaded")
        } else if (hasPlayed) {
            if (audioPlayer?.isPlaying)! {
                //pauses the play animation and then the audioplayer
                let pausedTime: CFTimeInterval = (cover?.layer.convertTime (CACurrentMediaTime (), from: nil))!
                cover?.layer.speed = 0.0
                cover?.layer.timeOffset = pausedTime
                audioPlayer?.pause ()
                self.isPaused = true
            } else if isPaused {
                //resumes the play animation and then the audio player
                let pausedTime:CFTimeInterval = (cover?.layer.timeOffset)!
                cover?.layer.speed = 1.0
                cover?.layer.timeOffset = 0.0
                cover?.layer.beginTime = 0.0
                let timeSincePause:CFTimeInterval = (cover?.layer.convertTime (CACurrentMediaTime (), from: nil))! - pausedTime
                cover?.layer.beginTime = timeSincePause
                self.isPaused = false
                audioPlayer?.play ()
            }
        } else {
            if hasWaveForm {
                //create waveform if requested
                UIView.animate (withDuration: getAudioTime (), delay: 0.0, options: [.curveLinear], animations: {
                    self.cover?.frame = CGRect (x: (self.view?.frame.maxX)!,
                                                y: (self.view?.frame.maxY)!-400,
                                                width: 0,
                                                height: 400)
                })
            }
            //starts the engine
            try! engine?.start()
            //prepare and play the engine and audioplayer
            engine?.prepare ()
            audioPlayer?.prepare (withFrameCount: (buffer?.frameLength)!)
            audioPlayer?.play ()
            //set the buffer to be played
            audioPlayer?.scheduleBuffer (buffer!, at: nil, completionHandler: nil)
            hasPlayed = true
        }
    }
    
    public func setBuffer (buf: AVAudioPCMBuffer) {
        /*
        this funtion sets an external buffer to the internal one. 
         flags the install as manually generated.
        */
        self.buffer = buf
        self.source = URL (string: "manual")
    }
    
    public func addBuffer (buf: AVAudioPCMBuffer,
                           withVolume: Float = 1,
                           atTime: Float = 0.0) throws {
        /*
         this function adds an external buffer to the current buffer. 
         the transform is 
         new_buffer = old_buffer + inc_buffer * volume
         flags the install as manually generated.
        */
        if buffer == nil {
            self.setBuffer (buf: buf)
        }
        //creater buffer
        let delay = atTime * 44100.0
        let inctime = buf.frameLength + AVAudioFrameCount (delay)
        let newtime = (inctime > (buffer?.frameLength)! ? inctime : (buffer?.frameLength)!)
        let finbuf = AVAudioPCMBuffer (pcmFormat: (buffer?.format)!,
                                       frameCapacity: newtime)
        finbuf.frameLength = newtime
        //create pointers
        guard var bufp = buffer?.floatChannelData?[0] else {
            throw AppLabAudioControllerErrors.FloatChannelDataIsNil
        }
        guard var incbufp = buf.floatChannelData?[0] else {
            throw AppLabAudioControllerErrors.FloatChannelDataIsNil
        }
        guard var finbufp = finbuf.floatChannelData?[0] else {
            throw AppLabAudioControllerErrors.FloatChannelDataIsNil
        }
        guard var bufp1 = buffer?.floatChannelData?[1] else {
            throw AppLabAudioControllerErrors.FloatChannelDataIsNil
        }
        guard var incbufp1 = buf.floatChannelData?[1] else {
            throw AppLabAudioControllerErrors.FloatChannelDataIsNil
        }
        guard var finbufp1 = finbuf.floatChannelData?[1] else {
            throw AppLabAudioControllerErrors.FloatChannelDataIsNil
        }
        //map old buffer and new buffer together
        for i in 0..<Int32 (finbuf.frameLength) {
            if i < Int32 ((buffer?.frameLength)!) {
                finbufp.pointee = bufp.pointee
                bufp = bufp.advanced(by: 1)
                finbufp1.pointee = bufp1.pointee
                bufp1 = bufp1.advanced(by: 1)
            }
            if i + 10 > Int32 (delay) && i < Int32 (inctime) {
                finbufp.pointee += incbufp.pointee * withVolume
                incbufp = incbufp.advanced(by: 1)
                finbufp1.pointee += incbufp1.pointee * withVolume
                incbufp1 = incbufp1.advanced(by: 1)
            }
            finbufp = finbufp.advanced(by: 1)
            finbufp1 = finbufp1.advanced(by: 1)
        }
        //finalize the add
        self.source = URL (string: "manual")
        buffer = finbuf
    }
    
    
    public func play () {
        /*
         public function to toggle play/pause
        */
        self.playpause ()
        print ("<playing music>")
    }
   /****************              <-depreciated->              ***************/
//    var capture: AVCaptureSession?
//    var device: AVCaptureDevice?
//    var input: AVCaptureDeviceInput?
//    var output: AVCaptureAudioDataOutput?
//    public func openCameraFunctionality () {
//        capture = AVCaptureSession ()
//        device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
//        print (device)
//        input = try! AVCaptureDeviceInput (device: device!)
//        output = AVCaptureAudioDataOutput ()
//        capture?.addInput(input!)
//        capture?.addOutput(output!)
//        capture?.startRunning()
//        print (capture?.isRunning ?? false)
//        playButton = UIView (frame: CGRect (x: 50.0,
//                                            y: 50.0,
//                                            width: 50.0, height: 50.0))
//        let tap = UITapGestureRecognizer (target: self, action: #selector (self.stoprecord))
//        playButton?.backgroundColor = UIColor.green
//                playButton?.addGestureRecognizer(tap)
//                view?.addSubview(playButton!)
//    }
//    
//    @objc public func stoprecord () {
//        capture?.stopRunning ()
//        print ("stopped recording")
//    }
//    
//    public func openRecordFunctionality () {
//        playButton = UIView (frame: CGRect (x: 50.0,
//                                            y: 50.0,
//                                            width: 50.0, height: 50.0))
//        let tap = UITapGestureRecognizer (target: self, action: #selector (self.record))
//        playButton?.backgroundColor = UIColor.green
//        playButton?.addGestureRecognizer(tap)
//        view?.addSubview(playButton!)
//    }
//    
//    @objc public func record () {
//        /*
//         this function is depreciated. 
//         audio recording does not work in playgrounds.
//        */
//        recorded = Bundle.main.resourceURL?.appendingPathComponent("audio.m4a")
//        let settings:[String : Any] = [AVFormatIDKey:kAudioFormatAppleLossless,
//                                        AVSampleRateKey:44100.0,
//                                        AVNumberOfChannelsKey:1,
//                                        AVEncoderBitRateKey:320000,
//                                        AVLinearPCMBitDepthKey:16,
//                                        AVEncoderAudioQualityKey:AVAudioQuality.max.rawValue]
//        print ((recorded?.absoluteString)!)
//        print (FileManager.default.fileExists(atPath: (recorded?.absoluteString)!))
//        try! audioSession?.setActive(true)
//        recorder = try! AVAudioRecorder (url: recorded!, settings:settings)
//        recorder?.delegate = self
//        recorder?.isMeteringEnabled = true
//        print ("recorder created")
//        recorder?.prepareToRecord ()
//        print ("attempting to record")
//        recorder?.record()
//        playButton?.backgroundColor = UIColor.red
//        playButton?.removeGestureRecognizer((playButton?.gestureRecognizers?[0])!)
//        let tap = UITapGestureRecognizer (target: self, action: #selector (self.stopRecord))
//        playButton?.addGestureRecognizer(tap)
//        print ("<recorder status: \((recorder?.isRecording)!)>")
//    }
//    
//    @objc public func stopRecord () {
//        /*
//         this function is depreciated.
//         audio recording does not work in playgrounds.
//        */
//        if (recorder != nil) {
//            recorder?.stop ()
//            recorder = nil
//            print ("<recorder has stopped>")
//            //loadAudio("audio")
//            //playpause()
//        }
//    }
    
    
}
