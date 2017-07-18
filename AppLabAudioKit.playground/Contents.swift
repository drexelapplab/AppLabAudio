import UIKit
import Foundation
import PlaygroundSupport
import AVFoundation


let view = UIView (frame: CGRect (x: 0, y: 0, width: 700, height: 450))


let draw = EnvelopeDrawer (frame: CGRect (x: 0, y: 0, width: 700, height: 400))
view.addSubview (draw)
let controller = AppLabAudioController (view)
draw.isUserInteractionEnabled = true
controller.setEnvelopeDrawer(draw)
try! controller.setBuffer(buf: AppLabBufferMaker (fromNote: Note (letter:Note.Letter.E, octave: 3) , forTime: 2.0).generate ())
draw.initPathGenerator ()
PlaygroundPage.current.liveView = view

