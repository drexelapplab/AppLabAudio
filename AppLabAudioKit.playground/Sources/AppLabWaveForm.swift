import UIKit
import AVFoundation
import AudioUnit
import CoreAudioKit
import XCPlayground
import PlaygroundSupport
import Accelerate

public class AppLabWaveForm: UIView {
    open var readfile:([Float], [CGFloat])
    open var synced:Int {
        return 0
    }
    open var totalBars:Int {
        return readfile.1.count
    }
    
    public init (audio: URL, frm:CGRect) {
        let file = try! AVAudioFile (forReading: audio)
        let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        readfile = ([], [])
        let buf = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
        try! file.read (into: buf)
        let umbp = UnsafeMutableBufferPointer (start: buf.floatChannelData?[0], count: Int (buf.frameLength))
        readfile.0 = umbp.map ({$0})
        
        super.init (frame: frm)
    }

    public init (buffer: AVAudioPCMBuffer, frm:CGRect) {
        readfile = ([], [])
        let buf = buffer
        let umbp = UnsafeMutableBufferPointer (start: buf.floatChannelData?[0], count: Int (buf.frameLength))
        readfile.0 = umbp.map ({$0})
        
        super.init (frame: frm)
    }
    
    public required init (coder aDecoder: NSCoder) {
        //do nothing :|
        self.readfile = ([], [])
        super.init (coder: aDecoder)!
    }
    
    override public func draw (_ rect: CGRect) {
        self.convertToPoints ()

        var f = 0
        
        let aPath = UIBezierPath ()
        let aPath2 = UIBezierPath ()

        aPath.lineWidth = rect.width / CGFloat (readfile.1.count) * 0.80
        aPath2.lineWidth = rect.width / CGFloat (readfile.1.count) * 0.80
        aPath.move (to: CGPoint (x:0.0 , y:rect.height/2))
        aPath2.move (to: CGPoint(x:0.0 , y:rect.height/2))
        
        for _ in readfile.1 {
            var x:CGFloat = rect.width / CGFloat (readfile.1.count)
            aPath.move (to: CGPoint (x:aPath.currentPoint.x + x , y:aPath.currentPoint.y))
            aPath.addLine (to: CGPoint (x:aPath.currentPoint.x  , y:aPath.currentPoint.y - (readfile.1[f] * 160) - 1.0))
            
            aPath2.move (to: CGPoint(x:aPath2.currentPoint.x + x , y:aPath2.currentPoint.y))
            aPath2.addLine (to: CGPoint(x:aPath2.currentPoint.x  , y:aPath2.currentPoint.y - ((-1.0 * readfile.1[f]) * 140)))
            
            aPath2.close ()
            aPath.close ()
            
            x += 1
            f += 1
        }
        
        UIColor.cyan.set ()
        aPath.stroke ()
        aPath.fill ()
        aPath2.stroke (with: CGBlendMode.normal, alpha: 0.5)
        aPath2.fill ()
    }
    
    func convertToPoints () {
        
        var processingBuffer = [Float](repeating: 0.0,
                                       count: Int (readfile.0.count))
        let sampleCount = vDSP_Length (readfile.0.count)
        vDSP_vabs (readfile.0, 1, &processingBuffer, 1, sampleCount);
        
        let samplesPerPixel = 50
        let filter = [Float](repeating: 1.0 / Float (samplesPerPixel),
                             count: samplesPerPixel)
        let downSampledLength = Int (readfile.0.count / samplesPerPixel)
        var downSampledData = [Float](repeating:0.0,
                                      count:downSampledLength)
        vDSP_desamp (processingBuffer,
                    vDSP_Stride (samplesPerPixel),
                    filter, &downSampledData,
                    vDSP_Length (downSampledLength),
                    vDSP_Length (samplesPerPixel))
        
        readfile.1 = downSampledData.map ({CGFloat ($0)})
        
    }
}


