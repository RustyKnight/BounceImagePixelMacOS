//
//  TitleView.swift
//  BouncyImage
//
//  Created by Shane Whitehead on 18/1/2022.
//

import Foundation
import AppKit
import SuperSimpleAnimatorKit
import Cadmus
import CoreUIExtensions

struct Tile {
    let bounds: CGRect
    let image: NSImage?
}

class TileContainerView: NSView {
    
    enum AnimationState {
        case image
        case randomise
    }
    
    private(set) var animationState = AnimationState.image
    
    var tiles: [Tile] = [] {
        didSet {
            tilesDidChange()
        }
    }
    
    private var animationProperties: [Pixel:PixelAnimationProperties] = [:]
    
    private var pixelImageSize = CGSize.zero
    
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
        let size = (radius * 2) + 10
        log(debug: "size = \(size); radius = \(radius); \(pixelImageSize)")
        return NSSize(width: size, height: size)
    }
    
    private var radius: CGFloat {
        return (min(pixelImageSize.width, pixelImageSize.height) / 2.0) * 1.5
    }

    private var tileViews: [TileView] {
        return subviews.compactMap { $0 as? TileView }
    }
    
    private var shouldIgnoreLayout = false
    
    override func layout() {
        guard !shouldIgnoreLayout else { return }
        if animationState == .image {
            for view in tileViews {
                guard let tile = view.tile else {
                    view.frame = .zero
                    continue
                }
                view.frame = CGRect(origin: positionOnScreen(tile), size: tile.bounds.size)
            }
        }
    }
    
    private func positionOnScreen(_ tile: Tile) -> CGPoint {
        let imageOffset = CGPoint.middle(bounds.size, pixelImageSize)
        let drawPoint = tile.bounds.origin + imageOffset
        return drawPoint
    }

    private func tilesDidChange() {
        defer {
            setNeedsDisplay(CGRect(origin: CGPoint.zero, size: pixelImageSize))
            needsLayout = true
        }
        guard !tiles.isEmpty else {
            pixelImageSize = CGSize.zero
            return
        }
        
        guard let maxBounds = (tiles.max { maxBounds($0.bounds, $1.bounds) })?.bounds else {
            return
        }
        
        pixelImageSize = CGSize(width: maxBounds.maxX, height: maxBounds.maxY)
        shouldIgnoreLayout = false
        
        for tile in tiles {
            let titleView = TileView()
            titleView.frame = CGRect(origin: positionOnScreen(tile), size: tile.bounds.size)
            titleView.tile = tile
            
            addSubview(titleView)
        }
    }
    
    private func maxBounds(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
        return lhs.origin.x + lhs.width < rhs.origin.x + rhs.width &&
        lhs.origin.y + lhs.height < rhs.origin.y + rhs.height
    }
    
    private let angleRange = CGFloat(0.0)..<360.0
    
    private func animate(_ view: TileView) {
        guard let tile = view.tile else { return }
        
        let durationRange = animationState == .randomise ? 3.0...5.0 : 1.0...3.0

        NSAnimationContext.runAnimationGroup({ context in
            let radius = self.radius
            let midPoint = bounds.midPoint

            var targetPoint = CGPoint.zero
            if animationState == .randomise {
                targetPoint = CGPoint.pointOnCircle(
                    center: midPoint,
                    radius: radius,
                    angle: CGFloat.random(in: angleRange).asDegrees.converted(to: .radians).value)
                
                targetPoint = targetPoint - CGPoint(x: tile.bounds.size.width / 2, y: tile.bounds.size.height / 2)
            } else {
                targetPoint = positionOnScreen(tile)
            }
            let duration = Double.random(in: durationRange)
            
            context.duration = duration
            
            var timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            if view.frame.origin == tile.bounds.origin {
                // If we're animating from our image position, then only ease out
                timingFunction = CAMediaTimingFunction(name: .easeOut)
            } else if targetPoint == self.positionOnScreen(tile) {
                // If we're animating to out image position, then only ease in
                timingFunction = CAMediaTimingFunction(name: .easeIn)
            }
            
            context.timingFunction = timingFunction
            view.animator().frame.origin = targetPoint
        }) { [weak self] in
            guard let self = self else { return }
            if self.animationState == .randomise {
                self.animate(view)
            } else if view.frame.origin != self.positionOnScreen(tile) {
                self.animate(view)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        let tileViews = tileViews
        if animationState == .image {
            animationState = .randomise
            for view in tileViews {
                animate(view)
            }
        } else {
            shouldIgnoreLayout = true
            animationState = .image
            for view in tileViews {
                animate(view)
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.saveGState()

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
}

class TileView: NSView {

    private var imageView: NSImageView = {
        let imageView = NSImageView()
        imageView.wantsLayer = true
        imageView.layer?.masksToBounds = true
        imageView.layer?.borderColor = NSColor.black.withAlphaComponent(0.5).cgColor
        imageView.layer?.borderWidth = 0.5
        return imageView
    }()
    
    var tile: Tile? {
        didSet {
            imageView.image = tile?.image
            if let bounds = tile?.bounds {
                imageView.layer?.cornerRadius = min(bounds.width / 4, bounds.height / 4)
            }
            needsLayout = true
        }
    }
    
    override var intrinsicContentSize: NSSize {
        guard let tile = tile else { return NSSize.zero }
        return tile.bounds.size
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layout() {
        imageView.frame = bounds
    }
    
    internal func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true
        addSubview(imageView)
    }

}
