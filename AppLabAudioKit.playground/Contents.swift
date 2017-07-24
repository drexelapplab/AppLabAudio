import UIKit
import Foundation
import PlaygroundSupport
import AVFoundation

let background = Background (withWidth: 700, andHeight: 450)
let slider = Slider (withWidth: 180, andHeight: 45)
let envelope = EnvelopeDrawer (frame:CGRect (x: 0, y: 0, width: 700, height: 400))
let audioPlayer = AppLabAudioController (background.view)
envelope.initPathGenerator ()
envelope.isUserInteractionEnabled = true
background.view.addSubview (envelope)
var buttons:[Box] = []

for i in 0..<5 {
    buttons.append (Box (withWidth: 45, andHeight: 45))
    background.place (buttons[i], atX: Double (i) * 50 + Double (i) * 5, andY: 405)
    buttons[i].roundCorners (toRadius: 5)
    buttons[i].setBackgroundColor (to: UIColor.green)
}
background.place(slider, atX: 510, andY: 405)

buttons[4].setBackgroundColor(to: UIColor.red)
var envelopes:[[Float]] = [EnvelopeDrawer.ClarinetEnvelope,
                           EnvelopeDrawer.GuitarEnvelope,
                           EnvelopeDrawer.PianoEnvelope,
                           EnvelopeDrawer.ViolinEnvelope]

var isInEditMode = true
var current = 0
buttons[0].addTouch (Touch ({
    if isInEditMode {
        if current != 0 {
            envelopes[current] = envelope.envelope ()
            envelope.displayEnvelope(envelopes[0])
            current = 0
        } else {
            envelopes[0] = envelope.envelope ()
        }
    } else {
        envelope.displayEnvelope(envelopes[0])
        current = 0
        let pitch = try! Pitch (frequency: Double (slider.getSliderValue () * 1000.0) + 30.0)
        let buffer = try! AppLabBufferMaker (fromPitch: pitch, forTime: 0.75)
        try! buffer.mapEnvelope(envelopes[0])
        audioPlayer.playBuffer(buffer.generate ())
    }
}))
buttons[1].addTouch (Touch ({
    if isInEditMode {
        if current != 1 {
            envelopes[current] = envelope.envelope ()
            envelope.displayEnvelope(envelopes[1])
            current = 1
        } else {
            envelopes[1] = envelope.envelope ()
        }
    } else {
        envelope.displayEnvelope(envelopes[1])
        current = 1
        let pitch = try! Pitch (frequency: Double (slider.getSliderValue () * 1000.0) + 30.0)
        let buffer = try! AppLabBufferMaker (fromPitch: pitch, forTime: 0.75)
        try! buffer.mapEnvelope(envelopes[1])
        audioPlayer.playBuffer(buffer.generate ())
    }
}))
buttons[2].addTouch (Touch ({
    if isInEditMode {
        if current != 2 {
            envelopes[current] = envelope.envelope ()
            envelope.displayEnvelope(envelopes[2])
            current = 2
        } else {
            envelopes[2] = envelope.envelope ()
        }
    } else {
        envelope.displayEnvelope(envelopes[2])
        current = 2
        let pitch = try! Pitch (frequency: Double (slider.getSliderValue () * 1000.0) + 30.0)
        let buffer = try! AppLabBufferMaker (fromPitch: pitch, forTime: 0.75)
        try! buffer.mapEnvelope(envelopes[2])
        audioPlayer.playBuffer(buffer.generate ())
    }
}))
buttons[3].addTouch (Touch ({
    if isInEditMode {
        if current != 3 {
            envelopes[current] = envelope.envelope ()
            envelope.displayEnvelope(envelopes[3])
            current = 3
        } else {
            envelopes[3] = envelope.envelope ()
        }
    } else {
        envelope.displayEnvelope(envelopes[3])
        current = 3
        let pitch = try! Pitch (frequency: Double (slider.getSliderValue () * 1000.0) + 30.0)
        let buffer = try! AppLabBufferMaker (fromPitch: pitch, forTime: 0.75)
        try! buffer.mapEnvelope(envelopes[3])
        audioPlayer.playBuffer(buffer.generate ())
    }
}))
buttons[4].addTouch (Touch ({
    if !isInEditMode {
        buttons[4].setBackgroundColor (to: UIColor.red)
        envelope.isUserInteractionEnabled = true
    } else {
        envelopes[current] = envelope.envelope ()
        buttons[4].setBackgroundColor (to: UIColor.green)
        envelope.isUserInteractionEnabled = false
    }
    isInEditMode = !isInEditMode
}))
