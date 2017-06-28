import UIKit
import Foundation
import XCPlayground
import PlaygroundSupport
import AVFoundation

let view = UIView (frame: CGRect (x: 0, y: 0, width: 700, height: 400))
PlaygroundPage.current.liveView  = view

var emajorscale = [try! Pitch (frequency: Note (letter: Note.Letter.E, octave: 3).frequency),    try! Pitch (frequency: Note (letter: Note.Letter.FSharp, octave: 3).frequency), try! Pitch (frequency: Note (letter: Note.Letter.GSharp, octave: 3).frequency), try! Pitch (frequency: Note (letter: Note.Letter.A, octave: 3).frequency),    try! Pitch (frequency: Note (letter: Note.Letter.B, octave: 3).frequency),    try! Pitch (frequency: Note (letter: Note.Letter.CSharp, octave: 4).frequency), try! Pitch (frequency: Note (letter: Note.Letter.DSharp, octave: 4).frequency), try! Pitch (frequency: Note (letter: Note.Letter.E, octave: 4).frequency)]
let controller = AppLabAudioController (view)

try! controller.setBuffer(buf: AppLabAudioController.concatBuffers(emajorscale.map ({
    (try! AppLabBufferMaker (fromPitch: $0, forTime: 0.5)).generate ()
})))

controller.showWaveForm ()
controller.showNotes ()
controller.play ()

//E, F♯, G♯, A, B, C♯, and D♯.
