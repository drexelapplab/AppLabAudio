import UIKit
import Foundation
import PlaygroundSupport
import AVFoundation

let background = Background (withWidth: 700, andHeight: 400)
let audioPlayer = AppLabAudioController (background.view)
let envelope = EnvelopeDrawer (frame: CGRect (x: 0, y:245, width: 700, height:155))
background.view.backgroundColor = UIColor.white
let Keys:[Box] = (0..<11).map ({_ in
    Box (withWidth: 50, andHeight: 70)
})
envelope.initPathGenerator ()
envelope.backgroundColor = UIColor.black
envelope.isUserInteractionEnabled = true
envelope.displayEnvelope(EnvelopeDrawer.GuitarEnvelope)
background.view.addSubview(envelope)


var start = try! Note (letter: Note.Letter.C, octave: 2)

var notes:[Note] = [
    try! Note (letter: Note.Letter.E, octave: 1),
    try! Note (letter: Note.Letter.E, octave: 2),
    try! Note (letter: Note.Letter.E, octave: 3),
    try! Note (letter: Note.Letter.E, octave: 4),
    try! Note (letter: Note.Letter.E, octave: 5),
    try! Note (letter: Note.Letter.A, octave: 1),
    try! Note (letter: Note.Letter.A, octave: 2),
    try! Note (letter: Note.Letter.A, octave: 3),
    try! Note (letter: Note.Letter.A, octave: 4),
    try! Note (letter: Note.Letter.A, octave: 5),
    try! Note (letter: Note.Letter.B, octave: 3)]

for i in 0..<11 {
    Keys[i].setBackgroundColor(to: UIColor.white)
    background.place(Keys[i], atX: Double (i) * 50.0 + Double (i) * 10 + 22.5, andY: 150)
    Keys[i].addBorder(ofSize: 2, andColor: UIColor.black)
    Keys[i].addTouch(Touch ({
        let buffer = try! AppLabBufferMaker (fromNote: notes[i], forTime: 0.25)
        try! buffer.mapEnvelope (envelope.envelope ())
        audioPlayer.playBuffer (buffer.generate ())
    }))
    start = try! start.higher ()
}

let title = Label (withWidth: 300, andHeight: 150)
let border = Box (withWidth: 700, andHeight: 20)
border.setBackgroundColor(to: UIColor.black)
title.setText(to: "Keyboard")
title.setFontColor(to: UIColor.black)
background.place(border, atX: 0, andY: 225)
background.place(title, atX: 200, andY: 0)
title.label?.font = title.label?.font.withSize(CGFloat (64))


