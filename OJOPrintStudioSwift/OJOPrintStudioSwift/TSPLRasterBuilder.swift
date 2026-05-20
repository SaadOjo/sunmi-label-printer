import AppKit
import Foundation

struct TSPLRasterBuilder {
    static func printData(widthMM: Double,
                          heightMM: Double,
                          gapMM: Double,
                          density: Int,
                          invertBitmapBits: Bool,
                          elements: [DesignerElement]) -> Data {
        let widthDots = max(80, Int((widthMM * Double(ojoDotsPerMillimeter)).rounded()))
        let heightDots = max(40, Int((heightMM * Double(ojoDotsPerMillimeter)).rounded()))
        let rowBytes = (widthDots + 7) / 8
        let blackPixels = monochromePixelMap(width: widthDots, height: heightDots, elements: elements)
        let bitmap = packedBitmap(width: widthDots,
                                  height: heightDots,
                                  rowBytes: rowBytes,
                                  blackPixels: blackPixels,
                                  invertBitmapBits: invertBitmapBits)

        var data = Data()
        append("SIZE \(number(widthMM)) mm,\(number(heightMM)) mm\r\n", to: &data)
        append("GAP \(number(gapMM)) mm,0\r\n", to: &data)
        append("SPEED 3\r\n", to: &data)
        append("DENSITY \(density)\r\n", to: &data)
        append("DIRECTION 1\r\n", to: &data)
        append("REFERENCE 0,0\r\n", to: &data)
        append("OFFSET 0 mm\r\n", to: &data)
        append("CLS\r\n", to: &data)
        append("BITMAP 0,0,\(rowBytes),\(heightDots),0,", to: &data)
        data.append(contentsOf: bitmap)
        append("\r\nPRINT 1,1\r\n", to: &data)
        return data
    }

    static func previewImage(widthMM: Double,
                             heightMM: Double,
                             elements: [DesignerElement]) -> NSImage {
        let widthDots = max(80, Int((widthMM * Double(ojoDotsPerMillimeter)).rounded()))
        let heightDots = max(40, Int((heightMM * Double(ojoDotsPerMillimeter)).rounded()))
        let blackPixels = monochromePixelMap(width: widthDots, height: heightDots, elements: elements)
        return previewImage(width: widthDots, height: heightDots, blackPixels: blackPixels)
    }

    static func summary(widthMM: Double,
                        heightMM: Double,
                        gapMM: Double,
                        density: Int,
                        invertBitmapBits: Bool,
                        elements: [DesignerElement]) -> String {
        let widthDots = max(80, Int((widthMM * Double(ojoDotsPerMillimeter)).rounded()))
        let heightDots = max(40, Int((heightMM * Double(ojoDotsPerMillimeter)).rounded()))
        let rowBytes = (widthDots + 7) / 8
        return """
        TSPL raster label
        SIZE \(number(widthMM)) mm,\(number(heightMM)) mm
        GAP \(number(gapMM)) mm,0
        Canvas \(widthDots) × \(heightDots) dots
        Bitmap \(rowBytes) bytes/row × \(heightDots) rows
        Payload \(rowBytes * heightDots) bitmap bytes
        Density \(density), Elements \(elements.count)
        Polarity \(invertBitmapBits ? "inverted bits" : "normal bits")
        """
    }

    private static func monochromePixelMap(width: Int, height: Int, elements: [DesignerElement]) -> [Bool] {
        let rep = renderBitmap(width: width, height: height, elements: elements)
        var blackPixels = [Bool](repeating: false, count: width * height)

        if let buffer = rep.bitmapData {
            let bytesPerRow = rep.bytesPerRow
            for y in 0..<height {
                let row = buffer.advanced(by: y * bytesPerRow)
                for x in 0..<width {
                    // renderBitmap draws into an 8-bit grayscale buffer: 0 = black, 255 = white.
                    blackPixels[y * width + x] = row[x] < 158
                }
            }
            return blackPixels
        }

        // Slow fallback; should not normally be used.
        for y in 0..<height {
            for x in 0..<width {
                blackPixels[y * width + x] = isBlack(rep.colorAt(x: x, y: y))
            }
        }
        return blackPixels
    }

    private static func packedBitmap(width: Int,
                                     height: Int,
                                     rowBytes: Int,
                                     blackPixels: [Bool],
                                     invertBitmapBits: Bool) -> [UInt8] {
        // Normal TSPL polarity is usually 1 = black. Some SUNMI label firmware/printer modes render the opposite.
        // When inverted, unused padding bits stay 1 so the right edge does not become a black stripe.
        var bitmap = [UInt8](repeating: invertBitmapBits ? 0xFF : 0x00, count: rowBytes * height)
        for y in 0..<height {
            for x in 0..<width {
                let mask = UInt8(0x80 >> (x % 8))
                let index = y * rowBytes + (x / 8)
                let black = blackPixels[y * width + x]
                if invertBitmapBits {
                    if black {
                        bitmap[index] &= ~mask
                    }
                } else if black {
                    bitmap[index] |= mask
                }
            }
        }
        return bitmap
    }

    private static func previewImage(width: Int, height: Int, blackPixels: [Bool]) -> NSImage {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: width,
                                   pixelsHigh: height,
                                   bitsPerSample: 8,
                                   samplesPerPixel: 1,
                                   hasAlpha: false,
                                   isPlanar: false,
                                   colorSpaceName: .deviceWhite,
                                   bytesPerRow: width,
                                   bitsPerPixel: 8)!
        rep.size = NSSize(width: width, height: height)

        if let buffer = rep.bitmapData {
            let bytesPerRow = rep.bytesPerRow
            for y in 0..<height {
                let row = buffer.advanced(by: y * bytesPerRow)
                for x in 0..<width {
                    row[x] = blackPixels[y * width + x] ? 0 : 255
                }
            }
        }

        let image = NSImage(size: NSSize(width: width, height: height))
        image.addRepresentation(rep)
        return image
    }

    private static func isBlack(_ color: NSColor?) -> Bool {
        guard let color = color?.usingColorSpace(.genericRGB) else {
            return false
        }
        let luminance = 0.299 * color.redComponent + 0.587 * color.greenComponent + 0.114 * color.blueComponent
        return color.alphaComponent > 0.05 && luminance < 0.62
    }

    private static func renderBitmap(width: Int, height: Int, elements: [DesignerElement]) -> NSBitmapImageRep {
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: width,
                                   pixelsHigh: height,
                                   bitsPerSample: 8,
                                   samplesPerPixel: 1,
                                   hasAlpha: false,
                                   isPlanar: false,
                                   colorSpaceName: .deviceWhite,
                                   bytesPerRow: width,
                                   bitsPerPixel: 8)!
        guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
            return rep
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        context.shouldAntialias = true

        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: width, height: height).fill()

        for element in elements {
            let rect = bottomLeftRect(forTopLeftRect: element.frameDots, canvasHeight: CGFloat(height))
            switch element.kind {
            case .image:
                if let image = element.image {
                    let fitRect = fittedRect(for: image, in: rect)
                    if let dithered = ditheredImage(from: image,
                                                    pixelWidth: max(1, Int(round(fitRect.width))),
                                                    pixelHeight: max(1, Int(round(fitRect.height)))) {
                        let previousInterpolation = context.imageInterpolation
                        context.imageInterpolation = .none
                        dithered.draw(in: fitRect, from: .zero, operation: .sourceOver, fraction: 1.0)
                        context.imageInterpolation = previousInterpolation
                    }
                }
            case .text:
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = element.alignment.nsAlignment
                paragraph.lineBreakMode = .byTruncatingTail

                let baseFont = NSFont(name: element.fontName, size: max(4, element.fontSizeDots))
                    ?? NSFont.systemFont(ofSize: max(4, element.fontSizeDots))
                let font: NSFont
                if element.isBold {
                    font = NSFontManager.shared.convert(baseFont, toHaveTrait: .boldFontMask)
                } else {
                    font = baseFont
                }

                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.black,
                    .paragraphStyle: paragraph
                ]
                (element.text as NSString).draw(in: rect, withAttributes: attributes)
            }
        }

        NSGraphicsContext.restoreGraphicsState()
        return rep
    }

    private static func fittedRect(for image: NSImage, in rect: NSRect) -> NSRect {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0, rect.width > 0, rect.height > 0 else {
            return rect
        }
        let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return NSRect(x: rect.midX - width / 2,
                      y: rect.midY - height / 2,
                      width: width,
                      height: height)
    }

    private static func ditheredImage(from image: NSImage, pixelWidth: Int, pixelHeight: Int) -> NSImage? {
        guard pixelWidth > 0, pixelHeight > 0 else {
            return nil
        }

        let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                   pixelsWide: pixelWidth,
                                   pixelsHigh: pixelHeight,
                                   bitsPerSample: 8,
                                   samplesPerPixel: 1,
                                   hasAlpha: false,
                                   isPlanar: false,
                                   colorSpaceName: .deviceWhite,
                                   bytesPerRow: pixelWidth,
                                   bitsPerPixel: 8)!
        rep.size = NSSize(width: pixelWidth, height: pixelHeight)
        guard let context = NSGraphicsContext(bitmapImageRep: rep), let buffer = rep.bitmapData else {
            return nil
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        context.imageInterpolation = .high
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight).fill()
        image.draw(in: NSRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight),
                   from: .zero,
                   operation: .sourceOver,
                   fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        let bytesPerRow = rep.bytesPerRow
        var values = [Double](repeating: 255, count: pixelWidth * pixelHeight)
        for y in 0..<pixelHeight {
            let row = buffer.advanced(by: y * bytesPerRow)
            for x in 0..<pixelWidth {
                values[y * pixelWidth + x] = Double(row[x])
            }
        }

        func addError(_ error: Double, x: Int, y: Int, factor: Double) {
            guard x >= 0, x < pixelWidth, y >= 0, y < pixelHeight else { return }
            let index = y * pixelWidth + x
            values[index] = min(255, max(0, values[index] + error * factor))
        }

        for y in 0..<pixelHeight {
            for x in 0..<pixelWidth {
                let index = y * pixelWidth + x
                let old = values[index]
                let newValue: Double = old < 158 ? 0 : 255
                let error = old - newValue
                values[index] = newValue
                addError(error, x: x + 1, y: y, factor: 7.0 / 16.0)
                addError(error, x: x - 1, y: y + 1, factor: 3.0 / 16.0)
                addError(error, x: x, y: y + 1, factor: 5.0 / 16.0)
                addError(error, x: x + 1, y: y + 1, factor: 1.0 / 16.0)
            }
        }

        for y in 0..<pixelHeight {
            let row = buffer.advanced(by: y * bytesPerRow)
            for x in 0..<pixelWidth {
                row[x] = values[y * pixelWidth + x] < 128 ? 0 : 255
            }
        }

        let output = NSImage(size: NSSize(width: pixelWidth, height: pixelHeight))
        output.addRepresentation(rep)
        return output
    }

    private static func bottomLeftRect(forTopLeftRect rect: CGRect, canvasHeight: CGFloat) -> NSRect {
        NSRect(x: rect.origin.x,
               y: canvasHeight - rect.origin.y - rect.height,
               width: rect.width,
               height: rect.height)
    }

    private static func append(_ string: String, to data: inout Data) {
        if let bytes = string.data(using: .utf8) {
            data.append(bytes)
        }
    }

    private static func number(_ value: Double) -> String {
        if abs(value - value.rounded()) < 0.001 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
