import UIKit
import AVFoundation
import AudioUnit
import CoreAudioKit
import PlaygroundSupport

public class EnvelopeDrawer: UIImageView {
    var lastPoint = CGPoint.zero
    var red: CGFloat = 0.0
    var green: CGFloat = 0.0
    var blue: CGFloat = 0.0
    var opacity: CGFloat = 1.0
    var swiped = false
    var samples = 90
    var points:[CGPoint] = []
    
    public func initPathGenerator () {
        points = (0..<samples).map ({
            return CGPoint (x: (CGFloat ($0) / CGFloat (samples)) * self.frame.maxX, y: self.frame.midY)
        })
        print (self.frame.maxY)
        self.redraw ()
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print ("touches began")
        swiped = false
        lastPoint = touches.first!.location(in: self)
        for i in 0..<points.count {
            if points[i].x > lastPoint.x {
                changePoint (at: i, to: lastPoint.y)
                break
                }
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print ("touches moved")
        swiped = true
        for touch in touches {
            let currentPoint = touch.location(in: self)
            for i in 0..<points.count {
                if points[i].x > currentPoint.x {
                    changePoint (at: i-1, to: currentPoint.y)
                    break
                }
            }
        self.redraw()
        }
    }
    
    private func changePoint (at: Int, to: CGFloat) {
        points.insert (CGPoint (x: points[at].x, y: to), at: at)
        points.remove (at: at+1)
    }
    
    func redraw () {
        UIGraphicsBeginImageContext(self.frame.size)
        self.image?.draw (in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        
        for point in points {
            let path1 = UIBezierPath ()
            path1.lineWidth = 0.8
            path1.move(to: CGPoint (x: point.x, y: self.frame.maxY))
            path1.addLine(to: CGPoint (x: point.x, y: self.frame.minY))
            UIColor.black.set ()
            path1.close()
            path1.stroke()
            let path2 = UIBezierPath ()
            path2.lineWidth = 0.8
            path2.move (to: CGPoint (x: point.x, y: self.frame.maxY))
            path2.addLine (to: point)
            let delta = Float (point.y / self.frame.maxY)
            print (delta)
            UIColor (colorLiteralRed: delta,
                     green: 0.0, blue: (1 - delta),
                     alpha: 2).set ()
            path2.close ()
            path2.stroke ()
        }

        
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        self.alpha = opacity
        UIGraphicsEndImageContext()
        
    }
    
    public func content () -> [Float] {
        return points.map {1.0 - Float ($0.y / self.frame.maxY)}
    }
    
}
