import UIKit
import Foundation
import PlaygroundSupport
import AVFoundation
import CoreMotion

let background = Background (withWidth: 690, andHeight: 300)
let audioPlayer = AppLabAudioController (background.view)
let box = Box(withWidth: 30, andHeight: 30)
box.roundCorners(toRadius: 15)
box.bevel()
box.setBackgroundColor(to: UIColor.darkGray)
background.setColor(to: UIColor (colorLiteralRed: 0.90, green: 0.90, blue: 0.90, alpha: 2))
background.place(box, atX: Double(background.view.frame.midX) - 15, andY: Double(background.view.frame.midY) - 15)
let manager = CMMotionManager()

if manager.isAccelerometerAvailable {
    manager.accelerometerUpdateInterval = 0.1
    manager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: {
        (data, error) in
        if let acceleration = data?.acceleration {
            
            var deltaX = 2 * acceleration.x + 1
            var deltaY = 2 * acceleration.y + 1
            let midX = Double(background.view.frame.midX)
            let midY = Double(background.view.frame.midY)
            
            UIView.animate(withDuration: 0.1, animations: { _ in
                let nx = midX / 2 + deltaX * midX / 2
                let ny = midY / 2 + deltaY * midY / 2
                box.view.center = CGPoint(x: nx,
                                          y: ny)
                
            })
            deltaY = acceleration.y + 1
            let newPitch = (deltaX + 1) * 500 + 50
            let newVolume = deltaY / 2
            audioPlayer.setVolume(to: Float(newVolume))
            audioPlayer.changePitch(to: Float(newPitch))
        }
    })
}

audioPlayer.playOnLoop ()
