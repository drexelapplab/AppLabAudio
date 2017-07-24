import Foundation
import UIKit
import PlaygroundSupport


public class Background {
    public var view: UIView
    
    public init (withWidth: Double, andHeight: Double) {
        view = UIView (frame: CGRect (x:0, y:0, width:withWidth, height: andHeight))
        PlaygroundPage.current.liveView = view
    }
    
    public func place (_ e: UIObject, atX: Double, andY: Double) {
        e.view.frame = CGRect (x: CGFloat (atX), y: CGFloat (andY),
                               width: e.view.frame.width, height: e.view.frame.height)
        view.addSubview (e.view)
    }
    
    public func setColor (to: UIColor) {
        self.view.backgroundColor = to
    }
}

public class UIObject {
    public var view: UIView
    
    public init () {
        view = UIView ()
    }
    
    public init (withWidth: Double, andHeight: Double) {
        view = UIView (frame: CGRect (x: 0, y: 0, width: withWidth, height: andHeight))
    }
    
    public func setBackgroundColor (to: UIColor) {
        view.backgroundColor = to
    }
    
}

public class Label: UIObject {
    public var label:UILabel?
    
    public override init (withWidth: Double, andHeight: Double) {
        super.init (withWidth: withWidth, andHeight: andHeight)
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
        label = UILabel (frame: view.frame)
        view.addSubview(label!)
        label?.textColor = UIColor.white
    }
    
    public func setText (to: String) {
        label?.text = to
    }
    
    public func setFontColor (to: UIColor) {
        label?.textColor = to
    }
}

public class Box: UIObject {
    public var touch:Touch?
    
    public func addTouch (_ t: Touch) {
        self.touch = t
        let tap = UITapGestureRecognizer (target: t, action: #selector (t.run))
        self.view.addGestureRecognizer(tap)
    }
    
    public func roundCorners (toRadius: Float) {
        self.view.layer.cornerRadius = CGFloat(toRadius)
    }
    
    public func addBorder (ofSize: Float, andColor: UIColor) {
        self.view.layer.borderWidth = CGFloat (ofSize)
        self.view.layer.borderColor = andColor.cgColor
    }
}

public class Slider: UIObject {
    public var slider: UISlider?
    
    public override init (withWidth: Double, andHeight: Double) {
        super.init (withWidth: withWidth, andHeight: andHeight)
        slider = UISlider (frame: view.frame)
        view.addSubview(slider!)
        slider?.layer.cornerRadius = 4
    }
    
    public override func setBackgroundColor(to: UIColor) {
        slider?.backgroundColor = to
    }
    
    public func getSliderValue () -> Float {
        return (slider?.value)! / (slider?.maximumValue)!
    }
}

public class Touch {
    private var exec:() -> Void
    @objc public func run () {
        self.exec ()
    }
    
    public init (_ block: @escaping () -> Void) {
        self.exec = block
    }
    
    
}


