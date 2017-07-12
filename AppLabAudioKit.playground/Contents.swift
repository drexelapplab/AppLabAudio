import UIKit
import Foundation
import PlaygroundSupport
import AVFoundation


let view = UIView (frame: CGRect (x: 0, y: 0, width: 700, height: 400))

let draw = EnvelopeDrawer (frame: view.frame)
let controller = AppLabAudioController (view)
let buffer = try! AppLabBufferMaker (fromNote: Note (letter: Note.Letter.E, octave: 4) , forTime: 2.0)
controller.setBuffer(buf:  buffer.generate ())

draw.initPathGenerator ()
view.addSubview(draw)
controller.setEnvelopeDrawer (draw)
draw.isUserInteractionEnabled = true

PlaygroundPage.current.liveView = view
//emajorscale: E, F♯, G♯, A, B, C♯, and D♯.
