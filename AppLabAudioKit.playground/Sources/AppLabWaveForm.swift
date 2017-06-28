import UIKit
import AVFoundation
import AudioUnit
import CoreAudioKit
import XCPlayground
import PlaygroundSupport
import Accelerate

public class AppLabWaveForm: UIView {
    //variables. some are lazy.
    open var readfile:([Float], [CGFloat])
    open var synced:Int {
        return 0
    }
    open var totalBars:Int {
        return readfile.1.count
    }
    
    public init (audio: URL, frm:CGRect) {
        /*
         this function loads audio into readfile and takes a frame to call to super.
        */
        //load file
        let file = try! AVAudioFile (forReading: audio)
        let format = AVAudioFormat (commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false)
        readfile = ([], [])
        //load file into buffer
        let buf = AVAudioPCMBuffer (pcmFormat: format, frameCapacity: UInt32 (file.length))
        try! file.read (into: buf)
        //map buffer info into readfile.0
        let umbp = UnsafeMutableBufferPointer (start: buf.floatChannelData?[0], count: Int (buf.frameLength))
        readfile.0 = umbp.map ({$0})
        //call super.init to setup visuals
        super.init (frame: frm)
    }

    public init (buffer: AVAudioPCMBuffer, frm:CGRect) {
        //create varuables
        readfile = ([], [])
        //localize buffer
        let buf = buffer
        let umbp = UnsafeMutableBufferPointer (start: buf.floatChannelData?[0], count: Int (buf.frameLength))
        //map buffer into readfile.0
        readfile.0 = umbp.map ({$0})
        //call super.init to setup visuals
        super.init (frame: frm)
    }
    
    public required init (coder aDecoder: NSCoder) {
        //do nothing :|
        self.readfile = ([], [])
        super.init (coder: aDecoder)!
    }
    
    override public func draw (_ rect: CGRect) {
        //formats display data into readfile.1
        self.convertToPoints ()

        var f = 0
        //paths to be drawn
        let aPath = UIBezierPath ()
        let aPath2 = UIBezierPath ()
        //settings for drawing
        aPath.lineWidth = rect.width / CGFloat (readfile.1.count) * 0.80
        aPath2.lineWidth = rect.width / CGFloat (readfile.1.count) * 0.80
        aPath.move (to: CGPoint (x:0.0 , y:rect.height/2))
        aPath2.move (to: CGPoint(x:0.0 , y:rect.height/2))
        
        for _ in readfile.1 {
            //determine width
            var x:CGFloat = rect.width / CGFloat (readfile.1.count)
            //draw path and path2
            aPath.move (to: CGPoint (x:aPath.currentPoint.x + x , y:aPath.currentPoint.y))
            aPath.addLine (to: CGPoint (x:aPath.currentPoint.x  , y:aPath.currentPoint.y - (readfile.1[f] * 160) - 1.0))
            aPath2.move (to: CGPoint(x:aPath2.currentPoint.x + x , y:aPath2.currentPoint.y))
            aPath2.addLine (to: CGPoint(x:aPath2.currentPoint.x  , y:aPath2.currentPoint.y - ((-1.0 * readfile.1[f]) * 140)))
            //setup for next bar
            aPath2.close ()
            aPath.close ()
            
            x += 1
            f += 1
        }
        //final settings and colors.
        UIColor.cyan.set ()
        aPath.stroke ()
        aPath.fill ()
        aPath2.stroke (with: CGBlendMode.normal, alpha: 0.5)
        aPath2.fill ()
    }
    
    func convertToPoints () {
        /*
         this function is meant to decrease the number of datapoints so that the sample data can be displayed more reasonably. 
         samplesPerPixel is the downsampling rate. the downsampling transforms is 
         downsized_sample = samples[n...n+samplesPerPixil].reduce (0, +) / samplesPerPixel
         the lower the samplesPerPixel the larger the displayed bars will be.
        */
        var processingBuffer = [Float](repeating: 0.0,
                                       count: Int (readfile.0.count))
        let sampleCount = vDSP_Length (readfile.0.count)
        vDSP_vabs (readfile.0, 1, &processingBuffer, 1, sampleCount);
        //set downsample setting
        let samplesPerPixel = 50
        let filter = [Float](repeating: 1.0 / Float (samplesPerPixel),
                             count: samplesPerPixel)
        let downSampledLength = Int (readfile.0.count / samplesPerPixel)
        var downSampledData = [Float](repeating:0.0,
                                      count:downSampledLength)
        //downsample array for visualization purposes
        vDSP_desamp (processingBuffer,
                    vDSP_Stride (samplesPerPixel),
                    filter, &downSampledData,
                    vDSP_Length (downSampledLength),
                    vDSP_Length (samplesPerPixel))
        //maps downSampledData to readfile.1
        readfile.1 = downSampledData.map ({CGFloat ($0)})
        
    }
}


