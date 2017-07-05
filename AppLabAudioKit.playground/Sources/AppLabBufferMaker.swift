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
    
    public static func concatBuffers (_ buffers:AVAudioPCMBuffer...) throws -> AVAudioPCMBuffer {
        /*
         this function strings the buffers given together one after the other.
         the transform is
         new_buffer = buffers.flatten ()
         */
        var len:UInt32 = 0
        for i in buffers {
            len += i.frameLength
        }
        //create final buffer
        let buf:AVAudioPCMBuffer = AVAudioPCMBuffer (pcmFormat: buffers[0].format, frameCapacity: len)
        buf.frameLength = len
        //setup pointers to final buffer
        guard var bufp1 = buf.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var bufp2 = buf.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        //look through given buffers
        for i in buffers {
            //setup pointers to buffers[i]
            guard var bufb1 = i.floatChannelData?[0] else {
                throw SimpleTransformerError.FloatChannelDataIsNil
            }
            guard var bufb2 = i.floatChannelData?[1] else {
                throw SimpleTransformerError.FloatChannelDataIsNil
            }
            //map buffers[i] to it's position on the new buffer
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
        /*
         this function strings the buffers given together one after the other.
         the transform is
         new_buffer = buffers.flatten ()
         */
        var len:UInt32 = 0
        for i in buffers {
            len += i.frameLength
        }
        //create final buffer
        let buf:AVAudioPCMBuffer = AVAudioPCMBuffer (pcmFormat: buffers[0].format, frameCapacity: len)
        buf.frameLength = len
        //setup pointers to new buffer
        guard var bufp1 = buf.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var bufp2 = buf.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        //look through buffers
        for i in buffers {
            //setup pointers to buffers[i]
            guard var bufb1 = i.floatChannelData?[0] else {
                throw SimpleTransformerError.FloatChannelDataIsNil
            }
            guard var bufb2 = i.floatChannelData?[1] else {
                throw SimpleTransformerError.FloatChannelDataIsNil
            }
            //map buffers[i] to its position in the new buffer
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
    
    public func transform (attack:Float  = -1,
                           decay:Float   = -1,
                           sustain:Float = -1,
                           sustainlvl:Float = -1) throws {
        /*
         this function is meant to map ADSR envelope onto the buffer. 
         all parameters are treated as percentages of the buffer. 
         sustainlvl is the volume help during sustain step. 
         if sustainlvl is nil or 0 then decay/sustain steps are skipped because it will end up being equal to the release stage.
         https://en.wikipedia.org/wiki/Synthesizer#/media/File:ADSR_parameter.svg
         release is assumed to be (1 - attack - decay - sustain) percentage.
         -transform (attack, decay, sustain) :- parameters are in percentage of buffer.
         |------attack-----|-decay-|---sustain---|-release-|
         |                 |       |             |         |
         |                /|\      |             |         |
         |               / | \     |             |         |
         |              /  |  \    |             |         |
         |             /   |   \   |             |         |
         |            /    |    \  |             |         |
         |           /     |     \ |             |         |
         |          /      |      \|             |         |
         |         /       |       |-------------|         |
         |        /        |       |             |\        |
         |       /         |       |             | \       |
         |      /          |       |             |  \      |
         |     /           |       |             |   \     |
         |    /            |       |             |    \    |
         |   /             |       |             |     \   |
         |  /              |       |             |      \  |
         | /               |       |             |       \ |
         |/                |       |             |        \|
         |-----------------|-------|-------------|---------|
         */
        //bounds checking to ensure no errors 
        let checksum = (attack  > 0 ? attack  : 0) +
                       (decay   > 0 ? decay   : 0) +
                       (sustain > 0 ? sustain : 0)
        if checksum > 1 {
            print ("invalid call to transform")
            print ("checksum > 1")
            return
        }
        guard var bufp1 = buffer.floatChannelData?[0] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        guard var bufp2 = buffer.floatChannelData?[1] else {
            throw SimpleTransformerError.FloatChannelDataIsNil
        }
        let frames = buffer.frameLength
        var i = 0
        /*
         attack (duration%:Float)
         scales buffer volume up to 100% over the percentage of the buffer provided.
         */
        if attack > 1 {
            print ("invalid call to transform")
            print ("attack > 1")
            return
        } else if attack > 0 {
            let deltap = (attack * Float (frames))
            while i < Int (deltap) {
                let vol = (Float (i) / deltap)
                bufp1.pointee = bufp1.pointee * vol
                bufp2.pointee = bufp2.pointee * vol
                bufp1 = bufp1.advanced(by: 1)
                bufp2 = bufp2.advanced(by: 1)
                i += 1
            }
        }
        /*
         decay (duration%:Float))
         scales down the volume to the sustainlvl over the given percentage of the buffer.
         */
        if sustainlvl > 0 && sustainlvl <= 1 {
            if decay > 1 {
                print ("invalid call to transform")
                print ("decay > 1")
                return
            } else if decay > 0 {
                let deltap = (decay * Float (frames))
                var j = 0
                let r = sustainlvl - 1
                while j < Int (deltap) {
                    let vol = 1 + (Float (j) / deltap) * (r)
                    bufp1.pointee = bufp1.pointee * vol
                    bufp2.pointee = bufp2.pointee * vol
                    bufp1 = bufp1.advanced(by: 1)
                    bufp2 = bufp2.advanced(by: 1)
                    i += 1
                    j += 1
                }
            }
            /*
             sustain (duration%:Float)
             maps sustain volume over the provided percentage of the buffer
             */
            if sustain > 1 {
                print ("invalid call to transform")
                print ("sustain > 1")
                return
            } else if sustain > 0 {
                let deltap = (attack * Float (frames))
                var j = 0
                while j < Int (deltap) {
                    bufp1.pointee = bufp1.pointee * sustainlvl
                    bufp2.pointee = bufp2.pointee * sustainlvl
                    bufp1 = bufp1.advanced(by: 1)
                    bufp2 = bufp2.advanced(by: 1)
                    i += 1
                    j += 1
                }
            }
        }
        /*
         release (implied)
         drops the volume to 0 from sustainlvl over the rest of the buffer.
         */
        let deltap = Float (frames) - Float (i)
        var j = 0
        let start = sustainlvl > 0 && sustainlvl <= 1 ? sustainlvl : 1
        while i < Int (frames) {
            let vol = (start - Float (j) / deltap * start)
            bufp1.pointee = bufp1.pointee * vol
            bufp2.pointee = bufp2.pointee * vol
            bufp1 = bufp1.advanced(by: 1)
            bufp2 = bufp2.advanced(by: 1)
            i += 1
            j += 1
        }
    }
    
//end def AppLabBufferMaker
}

