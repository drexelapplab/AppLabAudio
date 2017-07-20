import UIKit
import Foundation
import PlaygroundSupport
import AVFoundation


let background = Background (withWidth: 700, andHeight: 400)
let box = Box (withWidth: 100, andHeight: 100)
let label = Label (withWidth: 100, andHeight: 50)
let slider = Slider (withWidth: 200, andHeight: 25)

label.setText (to: "Hello World")
box.setBackgroundColor(to: UIColor.gray)
background.place (box, atX: 0, andY: 0)
background.place (label, atX: 300, andY: 100)
background.place(slider, atX: 300, andY: 150)
slider.setBackgroundColor(to: UIColor.white)

let touch = Touch ({
    print ("success!")
    print (slider.getSliderValue ())
})
box.roundCorners(toRadius: 5)
box.addTouch (touch)
