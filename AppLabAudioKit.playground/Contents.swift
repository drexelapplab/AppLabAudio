import UIKit
import Foundation
import XCPlayground
import PlaygroundSupport

let view = UIView (frame: CGRect (x: 0, y: 0, width: 700, height: 400))
PlaygroundPage.current.liveView  = view

var emajorscale = [try! Pitch (frequency: Note (letter: Note.Letter.E, octave: 3).frequency),    try! Pitch (frequency: Note (letter: Note.Letter.FSharp, octave: 3).frequency), try! Pitch (frequency: Note (letter: Note.Letter.GSharp, octave: 3).frequency), try! Pitch (frequency: Note (letter: Note.Letter.A, octave: 3).frequency),    try! Pitch (frequency: Note (letter: Note.Letter.B, octave: 3).frequency),    try! Pitch (frequency: Note (letter: Note.Letter.CSharp, octave: 4).frequency), try! Pitch (frequency: Note (letter: Note.Letter.DSharp, octave: 4).frequency), try! Pitch (frequency: Note (letter: Note.Letter.E, octave: 4).frequency)]
let controller = AppLabAudioController (view)
var j:Float = 0
for pitch in emajorscale {
    let buffer = try! AppLabBufferMaker (fromPitch: pitch, forTime: 0.5)
    try! controller.addBuffer(buf: buffer.generate (), atTime: j)
    j += 0.5
}
controller.showWaveForm ()
controller.play ()

//E, F♯, G♯, A, B, C♯, and D♯.
