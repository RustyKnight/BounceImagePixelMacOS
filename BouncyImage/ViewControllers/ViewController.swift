//
//  ViewController.swift
//  BouncyImage
//
//  Created by Shane Whitehead on 18/1/2022.
//

import Cocoa
import Cadmus

class ViewController: NSViewController {

    @IBOutlet weak var imageView: NSImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makePixelatedView()
//        makePixelView()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
//        preferredContentSize = NSSize(width: 600, height: 600)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    private func makePixelView() {
        if let image = NSImage(named: "MegaTokyo") {
            let pixels = image.pixels()
            let pixelView = PixelView()
            pixelView.pixels = pixels

            view.addSubview(pixelView)

            let size = pixelView.intrinsicContentSize

            NSLayoutConstraint.activate([
                pixelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                pixelView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                pixelView.widthAnchor.constraint(equalToConstant: size.width),
                pixelView.heightAnchor.constraint(equalToConstant: size.height),
            ])
        }
    }
    
    private func makePixelatedView() {
        let cellSize = 10.0
        if let image = NSImage(named: "MegaTokyo"), let pixelated = image.pixelated(size: cellSize) {
            
            let rows = ceil(image.size.height / cellSize)
            let cols = ceil(image.size.width / cellSize)
            
            let defaultCellSize = CGSize(width: cellSize, height: cellSize)
            
            var subImages: [Tile] = []
            for row in stride(from: 0, to: rows, by: 1.0) {
                for col in stride(from: 0, to: cols, by: 1.0)  {
                    //log(debug: "\(col)x\(row) * \(col * cellSize)x\(row * cellSize)")
                    
                    let origin = CGPoint(x: col * cellSize, y: row * cellSize)
                    
                    var targetCellSize = defaultCellSize
                    if origin.x + defaultCellSize.width > image.size.width {
                        targetCellSize.width = image.size.width - origin.x
                    }
                    if origin.y + defaultCellSize.height > image.size.height {
                        targetCellSize.height = image.size.height - origin.y
                    }
                    
                    let cellRect = CGRect(origin: origin, size: targetCellSize)
                    let subImage = pixelated.subImage(origin: origin, size: targetCellSize)
                    if subImage == nil {
                        log(warning: "\(col)x\(row) ~ \(cellRect)")
                    }
                    subImages.append(Tile(bounds: cellRect, image: subImage))
                }
            }

            let titleContainerView = TileContainerView()
            titleContainerView.tiles = subImages
            view.addSubview(titleContainerView)

            let size = titleContainerView.intrinsicContentSize
            log(debug: "size = \(size)")

            NSLayoutConstraint.activate([
                titleContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                titleContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                titleContainerView.widthAnchor.constraint(equalToConstant: size.width),
                titleContainerView.heightAnchor.constraint(equalToConstant: size.height),
            ])
//            NSLayoutConstraint.activate([
//                titleContainerView.topAnchor.constraint(equalTo: view.topAnchor),
//                titleContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//                titleContainerView.widthAnchor.constraint(equalToConstant: size.width),
//                titleContainerView.heightAnchor.constraint(equalToConstant: size.height),
//            ])
//
//            let imageView = NSImageView()
//            imageView.translatesAutoresizingMaskIntoConstraints = false
//            imageView.image = pixelated
//
//            view.addSubview(imageView)
//            NSLayoutConstraint.activate([
//                imageView.topAnchor.constraint(equalTo: view.topAnchor),
//                imageView.leadingAnchor.constraint(equalTo: titleContainerView.trailingAnchor),
//                imageView.widthAnchor.constraint(equalToConstant: pixelated.size.width),
//                imageView.heightAnchor.constraint(equalToConstant: pixelated.size.height),
//            ])
        }
    }

}

