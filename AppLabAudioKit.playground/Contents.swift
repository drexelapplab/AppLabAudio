import UIKit
import Foundation
import PlaygroundSupport
import AVFoundation

let draw = EnvelopeDrawer (frame: CGRect (x: 0, y: 0, width: 700, height: 400))
draw.isUserInteractionEnabled = true
draw.initPathGenerator ()
PlaygroundPage.current.liveView = draw
print ("hi")
//emajorscale: E, F♯, G♯, A, B, C♯, and D♯.
