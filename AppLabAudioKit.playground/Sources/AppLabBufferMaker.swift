import Foundation
import AVFoundation

public class AppLabBufferMaker {
    enum SimpleTransformerError: Error {
        case FloatChannelDataIsNil
    }
    //variables needed to make buffer
    private var format: AVAudioFormat = AVAudioFormat (standardFormatWithSampleRate: 44100.0, channels: 2)
    private var buffer: AVAudioPCMBuffer
    
    public init (fromFile: String) {
        /*
         this function will try to load a file into the buffer.
        */
        let source = Bundle.main.url (forResource: fromFile, withExtension: ".m4a")
        let file = try! AVAudioFile (forReading: source!)
        let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
        try! file.read (into: buffer)
    }
    
    public init (fromNote: Note, forTime: Float) throws {
        /*
         this function will attempt to generate a buffer lasting {forTime} seconds that produces {fromNote}'s frequency.
        */
        let pitch = try! Pitch (frequency: fromNote.frequency)
        //calculate buffer size
        let frames = Float (format.sampleRate) * forTime
        //create buffer
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))
        buffer.frameLength = AVAudioFrameCount (frames)
        //setup buffer pointers
        guard var channel0 = buffer.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var channel1 = buffer.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        let sr:Float = 44100.0
        //map each generated datapoint into the new buffer
        for i in 0..<Int (buffer.frameLength) {
            // (frequency * i * PI * 2) / framerate
            let t = Float (pitch.frequency) * Float(i) * 2 * Float(M_PI) / sr
            channel0.pointee = (sinf (t))
            channel0 = channel0.advanced(by: 1)
            channel1.pointee = (sinf (t))
            channel1 = channel1.advanced(by: 1)
        }
    }
    
    public init (fromPitch: Pitch, forTime: Float) throws {
        /*
         this function will attempt to generate a buffer lasting {forTime} seconds that produces {fromPitch}'s frequency.
         */
        //calculate buffer size
        let frames = Float (format.sampleRate) * forTime
        //create buffer
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))
        buffer.frameLength = AVAudioFrameCount (frames)
        //setup buffer pointers
        guard var channel0 = buffer.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var channel1 = buffer.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        let sr:Float = 44100.0
        //map each generated datapoint into the new buffer
        for i in 0..<Int (buffer.frameLength) {
            // (frequency * i * PI * 2) / framerate
            let t = Float (fromPitch.frequency) * Float(i) * 2 * Float(M_PI) / sr
            channel0.pointee = (sinf (t))
            channel0 = channel0.advanced(by: 1)
            channel1.pointee = (sinf (t))
            channel1 = channel1.advanced(by: 1)
        }
    }
    
    public init (fromBuffer: AVAudioPCMBuffer) {
        /*
         this function assigned an external buffer to the interal one.
        */
        buffer = fromBuffer
    }
    
    public func generate () -> AVAudioPCMBuffer {
        /*
         this function is a getter for the internal buffer. 
         there should not be a setter. 
        */
        return buffer
    }
    
    
}

