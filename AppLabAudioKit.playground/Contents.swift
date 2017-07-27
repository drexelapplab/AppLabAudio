import UIKit
import Foundation
import PlaygroundSupport
import AVFoundation

let background = Background (withWidth: 700, andHeight: 300)
let slider = Slider (withWidth: 180, andHeight: 45)
let envelope = EnvelopeDrawer (frame:CGRect (x: 8, y: 15, width: 670, height: 230))
let audioPlayer = AppLabAudioController (background.view)
envelope.initPathGenerator ()
envelope.isUserInteractionEnabled = true
background.view.addSubview (envelope)
var buttons:[Box] = []
envelope.backgroundColor = UIColor.black
for i in 0..<5 {
    buttons.append (Box (withWidth: 45, andHeight: 45))
    if i == 4 {
        background.place (buttons[i], atX: 285, andY: 250)
        buttons[i].setBackgroundColor (to: UIColor.white)
    } else {
        background.place (buttons[i], atX: Double (i) * 50 + 10, andY: 250)
        buttons[i].setBackgroundColor (to: UIColor.white)
    }
    buttons[i].roundCorners (toRadius: 5)
    
    buttons[i].bevel ()
}
var frequencies:[Float] = [0.0, 0.0, 0.0, 0.0]
let freql = Label (withWidth: 100, andHeight: 45)
background.place(freql, atX: 415, andY: 250)
freql.setText(to: "Frequency")
freql.setFontColor(to: UIColor.black)
background.place(slider, atX: 500, andY: 250)
background.setColor(to: UIColor (colorLiteralRed: 0.92, green: 0.92, blue: 0.92, alpha: 2))
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
            frequencies[current] = slider.getSliderValue ()
            slider.slider?.setValue(frequencies[0], animated: true)
            current = 0
        } else {
            envelopes[0] = envelope.envelope ()
            frequencies[0] = slider.getSliderValue ()
        }
    } else {
        if current != 0 {
            frequencies[current] = slider.getSliderValue ()
            envelope.displayEnvelope (envelopes[0])
            slider.slider?.setValue (frequencies[0], animated: true)
            current = 0
        }
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
            frequencies[current] = slider.getSliderValue ()
            slider.slider?.setValue(frequencies[1], animated: true)
            current = 1
        } else {
            envelopes[1] = envelope.envelope ()
            frequencies[1] = slider.getSliderValue ()
        }
    } else {
        if current != 1 {
            frequencies[current] = slider.getSliderValue ()
            envelope.displayEnvelope (envelopes[1])
            slider.slider?.setValue (frequencies[1], animated: true)
            current = 1
        }
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
            frequencies[current] = slider.getSliderValue ()
            slider.slider?.setValue(frequencies[2], animated: true)
            current = 2
        } else {
            envelopes[2] = envelope.envelope ()
            frequencies[2] = slider.getSliderValue ()
        }
    } else {
        if current != 2 {
            frequencies[current] = slider.getSliderValue ()
            envelope.displayEnvelope (envelopes[2])
            slider.slider?.setValue (frequencies[2], animated: true)
            current = 2
        }
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
            frequencies[current] = slider.getSliderValue ()
            slider.slider?.setValue (frequencies[3], animated: true)
            current = 3
        } else {
            envelopes[3] = envelope.envelope ()
            frequencies[2] = slider.getSliderValue ()
        }
    } else {
        if current != 3 {
            frequencies[current] = slider.getSliderValue ()
            envelope.displayEnvelope (envelopes[3])
            slider.slider?.setValue (frequencies[3], animated: true)
            current = 3
        }
        let pitch = try! Pitch (frequency: Double (slider.getSliderValue () * 1000.0) + 30.0)
        let buffer = try! AppLabBufferMaker (fromPitch: pitch, forTime: 0.75)
        try! buffer.mapEnvelope(envelopes[3])
        audioPlayer.playBuffer(buffer.generate ())
    }
}))

let l4 = UILabel (frame: CGRect (x: 0, y: 0, width: 45, height: 45))
buttons[4].view.addSubview (l4)
l4.text = "Play"
l4.textAlignment = .center

buttons[4].addTouch (Touch ({
    if !isInEditMode {
        buttons[4].setBackgroundColor (to: UIColor.red)
        envelope.isUserInteractionEnabled = true
        l4.text = "Play"
    } else {
        envelopes[current] = envelope.envelope ()
        buttons[4].setBackgroundColor (to: UIColor.green)
        envelope.isUserInteractionEnabled = false
        l4.text = "Edit"
    }
    isInEditMode = !isInEditMode
}))

let l0 = UILabel (frame: CGRect (x: 0, y: 0, width: 45, height: 45))
buttons[0].view.addSubview (l0)
l0.text = "1"
l0.textAlignment = .center

let l1 = UILabel (frame: CGRect (x: 0, y: 0, width: 45, height: 45))
buttons[1].view.addSubview (l1)
l1.text = "2"
l1.textAlignment = .center

let l2 = UILabel (frame: CGRect (x: 0, y: 0, width: 45, height: 45))
buttons[2].view.addSubview (l2)
l2.text = "3"
l2.textAlignment = .center

let l3 = UILabel (frame: CGRect (x: 0, y: 0, width: 45, height: 45))
buttons[3].view.addSubview (l3)
l3.text = "4"
l3.textAlignment = .center



