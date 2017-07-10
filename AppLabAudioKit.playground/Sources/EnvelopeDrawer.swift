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
    var paths:[(CGPoint, UIBezierPath)] = []
    
    public func initPathGenerator () {
        paths = (0..<samples).map ({
            return (CGPoint (x: (CGFloat ($0) / CGFloat (samples)) * self.frame.maxX, y: self.frame.midY),
                    UIBezierPath ())
        })
        
        self.redraw ()
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print ("touches began")
        swiped = false
        lastPoint = touches.first!.location(in: self)
        for i in 0..<paths.count {
            if paths[i].0.x > lastPoint.x {
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
            for i in 0..<paths.count {
                if paths[i].0.x > currentPoint.x {
                    changePoint (at: i-1, to: currentPoint.y)
                    break
                }
            }
        self.redraw()
        }
    }
    
    private func changePoint (at: Int, to: CGFloat) {
        paths.insert ((CGPoint (x: paths[at].0.x, y: to), paths[at].1), at: at)
        paths.remove (at: at+1)
        print (paths.count)
    }
    
    func redraw () {
        UIGraphicsBeginImageContext(self.frame.size)
        let context = UIGraphicsGetCurrentContext()
        self.image?.draw (in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height))
        
        context?.setFillColor(UIColor.black.cgColor)
        print (self.frame)
        context?.fill(self.frame)
        context?.clear (self.frame)
        //context?.addRect(self.frame)
        //context?.stroke(self.frame)
        
        for (point, _) in paths {
            let path2 = UIBezierPath ()
            path2.lineWidth = 0.8
            path2.move(to: CGPoint (x: point.x, y: self.frame.maxY))
            path2.addLine(to: CGPoint (x: point.x, y: self.frame.minY))
            UIColor.black.set ()
            path2.close()
            path2.stroke()
            let path = UIBezierPath ()
            UIColor.cyan.set ()
            path.lineWidth = 0.8
            path.move (to: CGPoint (x: point.x, y: self.frame.maxY))
            path.addLine (to: point)
            path.close ()
            path.stroke ()
            //context?.addPath(path.cgPath)
        }

        
        self.image = UIGraphicsGetImageFromCurrentImageContext()
        self.alpha = opacity
        UIGraphicsEndImageContext()
        
    }
    
}
