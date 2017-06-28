import Foundation
import AVFoundation

public class AppLabPitchEngine {
    /*
     this class is meant to guess the most dominant note in the {buf}. 
     It uses the YIN algorithm. look @ YIN folder for implementation 
     */
    var transformer:YINTransformer
    var estimator:YINEstimator
    public init () {
        print ("<creating Pitch Engine>")
        estimator = YINEstimator ()
        transformer = YINTransformer ()
    }
    public func pitch (from buff: AVAudioPCMBuffer, withRate rate: Double) {
        let buffer = try? transformer.transform(buffer: buff)
        if (buffer != nil) {
            let est = try? estimator.estimateFrequency(sampleRate: Float (rate),
                                                       buffer: buffer!)
            if (est != nil) {
                let pitch = try? Pitch (frequency: Double (est!))
                if (pitch != nil) {
                    print ("\((pitch?.frequency)!)->\((pitch?.note.string)!)")
                }
            }
        }
    }
}

