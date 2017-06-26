import Foundation
import AVFoundation

public class AppLabBufferMaker {
    enum SimpleTransformerError: Error {
        case FloatChannelDataIsNil
    }
    private var format: AVAudioFormat = AVAudioFormat (standardFormatWithSampleRate: 44100.0, channels: 2)
    private var buffer: AVAudioPCMBuffer
    
    public init (fromFile: String) {
        let source = Bundle.main.url (forResource: fromFile, withExtension: ".m4a")
        let file = try! AVAudioFile (forReading: source!)
        let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
        try! file.read (into: buffer)

    }
    public init (fromNote: Note, forTime: Float) throws {
        let pitch = try! Pitch (frequency: fromNote.frequency)
        let frames = Float (format.sampleRate) * forTime
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))
        buffer.frameLength = AVAudioFrameCount (frames)
        guard var channel0 = buffer.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var channel1 = buffer.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        let sr:Float = 44100.0
        for i in 0..<Int (buffer.frameLength) {
            let t = Float (pitch.frequency) * Float(i) * 2 * Float(M_PI) / sr
            channel0.pointee = (sinf (t))
            channel0 = channel0.advanced(by: 1)
            channel1.pointee = (sinf (t))
            channel1 = channel1.advanced(by: 1)
        }
    }
    
    public init (fromPitch: Pitch, forTime: Float) throws {
        let frames = Float (format.sampleRate) * forTime
        buffer = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: AVAudioFrameCount(frames))
        buffer.frameLength = AVAudioFrameCount (frames)
        guard var pointer1 = buffer.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var pointer2 = buffer.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        let sr:Float = 44100.0
        for i in 0..<Int (buffer.frameLength) {
            let t = Float (fromPitch.frequency) * Float(i) * 2 * Float(M_PI) / sr
            pointer1.pointee = (sinf (t))
            pointer1 = pointer1.advanced(by: 1)
            pointer2.pointee = (sinf (t))
            pointer2 = pointer2.advanced(by: 1)
        }
    }
    public init (fromBuffer: AVAudioPCMBuffer) {
        buffer = fromBuffer
    }
    
    public func generate () -> AVAudioPCMBuffer {
        return buffer
    }
    
    
}

