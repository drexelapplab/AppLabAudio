import Foundation
import UIKit

public class Background {
    private var view: UIView
    
    public init () {
        view = UIView ()
    }
    
    public func place (_ e: UIElement) {
        view.addSubview (e.view)
    }
}

public class UIElement {
    public var view: UIView
    
    public init () {
        view = UIView ()
    }
    
    public init (frame: CGRect) {
        view = UIView (frame: frame)
    }
    
}

public class Label: UIElement {
    public var label:UILabel?
    
    public override init (frame: CGRect) {
        super.init(frame: frame)
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
    }
    
    public func setText (_ str:String) {
        if label != nil {
            view.willRemoveSubview(label!)
        }
        label = UILabel (frame: view.frame)
        view.addSubview(label!)
        label?.text = str
    }
}

public class Box: UIElement {
    public var touch:Touch?
    
    
    public func addTouch (_ t: Touch) {
        self.touch = t
        let tap = UITapGestureRecognizer (target: t, action: #selector (t.run))
        self.view.addGestureRecognizer(tap)
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


