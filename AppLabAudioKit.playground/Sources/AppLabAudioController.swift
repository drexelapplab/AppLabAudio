import UIKit
import AVFoundation
import AudioUnit
import CoreAudioKit
import XCPlayground
import PlaygroundSupport

public class AppLabAudioController {
    var playButton: UIView?
    var noteView: UIView?
    var view: UIView?
    var cover: UIView?
    var source: URL?
    
    var waveform: AppLabWaveForm?
    var pitchEngine: AppLabPitchEngine?
    
    var audioSession:AVAudioSession?
    var sampler:AVAudioUnitSampler?
    var distorter:AVAudioUnitDistortion?
    var reverber:AVAudioUnitReverb?
    var audioPlayer:AVAudioPlayerNode?
    var buffer:AVAudioPCMBuffer?
    var engine:AVAudioEngine?
    
    var isPaused:Bool
    var hasPlayed:Bool
    var hasWaveForm:Bool
    
    enum SimpleTransformerError: Error {
        case FloatChannelDataIsNil
    }
    
    public init (_ page: UIView) {
        hasPlayed = false
        isPaused = true
        hasWaveForm = false
        PlaygroundPage.current.needsIndefiniteExecution = true
        audioSession = AVAudioSession.sharedInstance ()
        view = page
        source = nil
        do {
            try audioSession?.setCategory (AVAudioSessionCategoryPlayAndRecord)
            try audioSession?.setActive (true)
            self.loadEngineModules ()
            engine = AVAudioEngine ()
            engine?.attach (sampler!)
            engine?.attach (distorter!)
            engine?.attach (reverber!)
            engine?.attach (audioPlayer!)
            self.connectEngineModules ()
            self.loadUI ()
        } catch {
            print ("Error creating Audio Session!")
        }
    }
    
    public init (_ page: UIView, withAudio audio: String) {
        hasPlayed = false
        isPaused = true
        hasWaveForm = false
        PlaygroundPage.current.needsIndefiniteExecution = true
        audioSession = AVAudioSession.sharedInstance ()
        view = page
        source = Bundle.main.url (forResource: audio, withExtension: ".m4a")
        do {
            try audioSession?.setCategory (AVAudioSessionCategoryPlayAndRecord)
            try audioSession?.setActive (true)
            self.loadEngineModules ()
            engine = AVAudioEngine ()
            engine?.attach (sampler!)
            engine?.attach (distorter!)
            engine?.attach (reverber!)
            engine?.attach (audioPlayer!)
            self.connectEngineModules ()
            let file = try! AVAudioFile (forReading: source!)
            let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
            buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
            try! file.read (into: buffer!)
            engine?.prepare ()
            audioPlayer?.prepare (withFrameCount: (buffer?.frameLength)!)
            self.loadUI ()
        } catch {
            print ("Error creating Audio Session!")
        }
    }
    
    public func loadAudio (_ audio: String) -> AppLabAudioController {
        source = Bundle.main.url (forResource: audio, withExtension: ".m4a")
        let file = try! AVAudioFile (forReading: source!)
        let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
        try! file.read (into: buffer!)
        return self
    }
    
    public func showNotes () -> AppLabAudioController {
        if source == nil {
            print ("no audio loaded")
        } else {
            if pitchEngine == nil {
                pitchEngine = AppLabPitchEngine ()
            }
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
        return self
    }
    
    public func showWaveForm () -> AppLabAudioController {
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
            cover?.backgroundColor = UIColor.black
            cover?.alpha = 0.5
            cover?.layer.opacity = 0.5
            cover?.layer.isOpaque = true
            view?.addSubview (waveform!)
            view?.addSubview (cover!)
            view?.bringSubview (toFront: cover!)
        }
        hasWaveForm = true
        return self
    }
    
    func getAudioTime () -> TimeInterval {
        if source == nil {
            print ("no audio loaded")
            return 0
        } else {
            let nsamples = buffer?.frameLength
            let time = Double (nsamples!) / (buffer?.format.sampleRate)!
            print ("song time is: \(time)")
            return time
        }
    }
    
    public func tapAudio (withBlock:@escaping (AVAudioPCMBuffer, Double) -> Void, onChunksOfSize size: Int) {
        if source == nil {
            print ("no audio loaded")
        } else {
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
    
    public func add (distortion: Float) -> AppLabAudioController {
        if source == nil {
            print ("no audio loaded")
        } else {
            self.distorter?.wetDryMix = distortion
        }
        return self
    }
    
    public func add (reverb: Float) -> AppLabAudioController {
        if source == nil {
            print ("no audio loaded")
        } else {
            self.reverber?.wetDryMix = reverb
        }
        return self
    }
    
    public func add (timeScale: Float) -> AppLabAudioController {
        if source == nil {
            print ("no audio loaded")
        } else {
            self.audioPlayer?.rate = timeScale
        }
        return self
    }
    
    func loadEngineModules () {
        print ("<creating Audio Engine Modules>")
        audioPlayer = AVAudioPlayerNode ()
        sampler = AVAudioUnitSampler ()
        distorter = AVAudioUnitDistortion ()
        reverber = AVAudioUnitReverb ()
        buffer = nil
    }
    
    func connectEngineModules () {
        print ("<connecting Audio Engine Modules>")
        let node = engine?.mainMixerNode
        let format = AVAudioFormat (standardFormatWithSampleRate: 44100.0, channels: 2)
        let pformat = buffer?.format
        engine?.connect (audioPlayer!, to: reverber!, format: pformat)
        engine?.connect (reverber!, to: node!, fromBus: 0, toBus: 0, format: pformat)
        engine?.connect (distorter!, to: node!, fromBus: 0, toBus: 2, format: format)
        let dNodes = [AVAudioConnectionPoint (node: (engine?.mainMixerNode)!, bus:1), AVAudioConnectionPoint (node:distorter!, bus:0)]
        engine?.connect (sampler!, to: dNodes, fromBus: 0, format: format)
    }
    
    func loadUI () {
        
    }
    
    @objc func playpause () {
        if source == nil {
            print ("no audio loaded")
        } else if (hasPlayed) {
            if (audioPlayer?.isPlaying)! {
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
            }
        } else {
            if hasWaveForm {
                UIView.animate (withDuration: getAudioTime (), delay: 0.0, options: [.curveLinear], animations: {
                    self.cover?.frame = CGRect (x: (self.view?.frame.maxX)!,
                                                y: (self.view?.frame.maxY)!-400,
                                                width: 0,
                                                height: 400)
                })
            }
            try! engine?.start()
            engine?.prepare ()
            audioPlayer?.prepare (withFrameCount: (buffer?.frameLength)!)
            audioPlayer?.play ()
            audioPlayer?.scheduleBuffer (buffer!, at: nil, completionHandler: nil)
            hasPlayed = true
        }
    }
    
    public func setBuffer (buf: AVAudioPCMBuffer) -> AppLabAudioController {
        self.buffer = buf
        self.source = URL (string: "manual")
        return self
    }
    
    public func addBuffer (buf: AVAudioPCMBuffer, withVolume: Float = 1, atTime: Float = 0.0) throws -> AppLabAudioController {
        if buffer == nil {
            return self.setBuffer (buf: buf)
        }
        let delay = atTime * 44100.0
        let inctime = buf.frameLength + AVAudioFrameCount (delay)
        let newtime = (inctime > (buffer?.frameLength)! ? inctime : (buffer?.frameLength)!)
        let finbuf = AVAudioPCMBuffer (pcmFormat: (buffer?.format)!,
                                       frameCapacity: newtime)
        finbuf.frameLength = newtime
        
        guard var bufp = buffer?.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var incbufp = buf.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var finbufp = finbuf.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var bufp1 = buffer?.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var incbufp1 = buf.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var finbufp1 = finbuf.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        
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


        self.source = URL (string: "manual")
        buffer = finbuf
        return self
    }
    
    public static func concatBuffers (_ buffers:AVAudioPCMBuffer...) throws -> AVAudioPCMBuffer {
        var len:UInt32 = 0
        for i in buffers {
            len += i.frameLength
        }
        let buf:AVAudioPCMBuffer = AVAudioPCMBuffer (pcmFormat: buffers[0].format, frameCapacity: len)
        buf.frameLength = len
        guard var bufp1 = buf.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var bufp2 = buf.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        
        for i in buffers {
            guard var bufb1 = i.floatChannelData?[0] else {
                throw SimpleTransformerError.FloatChannelDataIsNil
            }
            guard var bufb2 = i.floatChannelData?[1] else {
                throw SimpleTransformerError.FloatChannelDataIsNil
            }
            for _ in 0..<i.frameLength {
                bufp1.pointee = bufb1.pointee
                bufp2.pointee = bufb2.pointee
                bufp1 = bufp1.advanced(by: 1)
                bufp2 = bufp2.advanced(by: 1)
                bufb1 = bufb1.advanced(by: 1)
                bufb2 = bufb2.advanced(by: 1)
            }
        }
        return buf
    }
    
    public static func concatBuffers (_ buffers:[AVAudioPCMBuffer]) throws -> AVAudioPCMBuffer {
        var len:UInt32 = 0
        for i in buffers {
            len += i.frameLength
        }
        let buf:AVAudioPCMBuffer = AVAudioPCMBuffer (pcmFormat: buffers[0].format, frameCapacity: len)
        buf.frameLength = len
        guard var bufp1 = buf.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var bufp2 = buf.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        
        for i in buffers {
            guard var bufb1 = i.floatChannelData?[0] else {
                throw SimpleTransformerError.FloatChannelDataIsNil
            }
            guard var bufb2 = i.floatChannelData?[1] else {
                throw SimpleTransformerError.FloatChannelDataIsNil
            }
            for _ in 0..<i.frameLength {
                bufp1.pointee = bufb1.pointee
                bufp2.pointee = bufb2.pointee
                bufp1 = bufp1.advanced(by: 1)
                bufp2 = bufp2.advanced(by: 1)
                bufb1 = bufb1.advanced(by: 1)
                bufb2 = bufb2.advanced(by: 1)
            }
        }
        return buf
    }
    
    public func play () -> AppLabAudioController {
        self.playpause ()
        print ("<playing music>")
        return self
    }
    
}
