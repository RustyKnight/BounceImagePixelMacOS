//
//  PixelView.swift
//  BouncyImage
//
//  Created by Shane Whitehead on 18/1/2022.
//

import Foundation
import Cocoa
import Cadmus
import CoreUIExtensions
import SuperSimpleAnimatorKit

class PixelView: NSView {
    
    enum AnimationState {
        case image
        case randomise
    }
    
    private(set) var animationState = AnimationState.image
    
    var pixels: [Pixel] = [] {
        didSet {
            pixelsDidChange()
        }
    }
    
    private var animationProperties: [Pixel:PixelAnimationProperties] = [:]
    
    private var pixelImageSize = CGSize.zero
    
    private lazy var animator: LinearAnimator = {
        let animator = LinearAnimator { [weak self] animator in
            guard let self = self else {
                animator.stop()
                return
            }
            self.didTick()
        }
        return animator
    }()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    internal func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        //        layer?.backgroundColor = NSColor.red.cgColor
    }
    
    override var intrinsicContentSize: NSSize {
        let size = max(pixelImageSize.width + 1, pixelImageSize.height + 1) * 1.5
        return NSSize(width: size, height: size)
    }
    
    private func pixelsDidChange() {
        defer {
            setNeedsDisplay(CGRect(origin: CGPoint.zero, size: pixelImageSize))
            resizeSubviews(withOldSize: bounds.size)
        }
        guard !pixels.isEmpty else {
            pixelImageSize = CGSize.zero
            return
        }
        guard let width = (pixels.max { $0.point.x < $1.point.x })?.point.x,
              let height = (pixels.max { $0.point.y < $1.point.y })?.point.y else {
                  return
              }
        
        pixelImageSize = CGSize(width: width, height: height)
    }
    
    private let pixelSize = CGSize(width: 1, height: 1)
    
    private var radius: CGFloat {
        return min(bounds.width, bounds.height) / 2.0
    }
    
    private func toScreenPoint(_ pixel: Pixel) -> CGPoint {
        let imageOffset = CGPoint.middle(bounds.size, pixelImageSize)
        let drawPoint = pixel.point + imageOffset
        return drawPoint
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.saveGState()
        for pixel in pixels {
            pixel.color.setFill()
            var drawPoint = animationProperties[pixel]?.currentPosition ?? toScreenPoint(pixel)
            ctx.fill(NSRect(origin: drawPoint, size: pixelSize))
        }
        
        let strokeWidth = 2.0
        let radius = self.radius - (strokeWidth / 2)
        let diameter = radius * 2
        
        let midPoint = bounds.midPoint
        let anchorPoint = midPoint - radius
        
        ctx.setStrokeColor(NSColor.darkGray.cgColor)
        ctx.setLineWidth(2)
        ctx.strokeEllipse(in: CGRect(origin: anchorPoint, size: CGSize(width: diameter, height: diameter)))
        
        ctx.restoreGState()
    }

    func pointOnCircle(radius: CGFloat, angle: CGRadians) -> CGPoint {
        log(debug: "rads = \(angle)")
        let x = radius * cos(angle)
        let y = radius * sin(angle)
        
        return CGPoint(x: x, y: y)
    }

    override func mouseDown(with event: NSEvent) {
        
        animator.stop()
        switch animationState {
        case .image:
            animationProperties.removeAll()
            let angleRange = CGFloat(0.0)..<360.0
            let durationRange = 3.0...5.0
            let radius = self.radius

            let midPoint = bounds.midPoint
            
            var counter = 0
            for pixel in pixels {
                defer {
                    counter += 1
                }
                guard counter % 100 == 0 else { continue }
                let targetPoint = CGPoint.pointOnCircle(
                    center: midPoint,
                    radius: radius,
                    angle: CGFloat.random(in: angleRange).asDegrees.converted(to: .radians).value)
                let duration = Double.random(in: durationRange)

                let properties = PixelAnimationProperties(pixel: pixel,
                                                          fromPoint: toScreenPoint(pixel),
                                                          toPoint: targetPoint,
                                                          easement: .easeOut,
                                                          animationDuration: duration)
                animationProperties[pixel] = properties
            }
            animator.start()
        case .randomise:
            // Stop everything, rebuild all the animation
            // properties so that the from is the current position
            // and the to position is the pixel position
            // Restart
            break
        }
    }
    
    private func didTick() {
        setNeedsDisplay(bounds)
    }
}

extension CGPoint {
    
    static func middle(_ lhs: CGSize, _ rhs: CGSize) -> CGPoint {
        let middleX: CGFloat = (lhs.width - rhs.width) / 2.0
        let middleY: CGFloat = ((lhs.height - rhs.height) / 2.0)
        
        return CGPoint(x: middleX, y: middleY)
    }
    
}

struct PixelAnimationProperties {
    public enum Curve {
        case `default`
        case easeIn
        case easeInEaseOut
        case easeOut
        case linear
        
        var mediaTimingFunction: CAMediaTimingFunction {
            switch self {
            case .default: return CAMediaTimingFunction(name: .default)
            case .easeIn: return CAMediaTimingFunction(name: .easeIn)
            case .easeInEaseOut: return CAMediaTimingFunction(name: .easeInEaseOut)
            case .easeOut: return CAMediaTimingFunction(name: .easeOut)
            case .linear: return CAMediaTimingFunction(name: .linear)
            }
        }
    }
    
    let pixel: Pixel
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let easement: Curve
    let epoch: Date
    let animationDuration: TimeInterval
    
    init(pixel: Pixel, fromPoint: CGPoint, toPoint: CGPoint, easement: Curve, animationDuration: TimeInterval) {
        self.pixel = pixel
        self.fromPoint = fromPoint
        self.toPoint = toPoint
        self.easement = easement
        self.animationDuration = animationDuration
        self.epoch = Date()
    }
    
    private var progression: CGFloat {
        let runningTime = Date().timeIntervalSince(epoch)
        return max(0, min(1, runningTime / animationDuration))
    }
    
    var currentPosition: CGPoint {
        let curveProgression = easement.mediaTimingFunction.value(atTime: progression)
        return CGPoint.pointBetween(fromPoint, to: toPoint, progression: curveProgression)
    }
}

extension CGPoint {
    static func pointBetween(_ from: CGPoint, to: CGPoint, progression: Double) -> CGPoint {
        let x = cgfloat(min: from.x, max: to.x, at: progression)
        let y = cgfloat(min: from.y, max: to.y, at: progression)
        
        return CGPoint(x: x, y: y)
    }
}

func - (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x - rhs, y: lhs.y - rhs)
}

func -= (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
    return CGPoint(x: lhs.x - rhs, y: lhs.y - rhs)
}
//
//func + (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
//    return CGPoint(x: lhs.x + rhs, y: lhs.y + rhs)
//}
//
//func += (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
//    return CGPoint(x: lhs.x + rhs, y: lhs.y + rhs)
//}


extension CGPoint {
    func valueOfProgression(atTime progress: Double, to: CGPoint) -> CGPoint {
        let x = cgfloat(min: x, max: to.x, at: progress)
        let y = cgfloat(min: y, max: to.y, at: progress)
        return CGPoint(x: x, y: y)
    }
}
