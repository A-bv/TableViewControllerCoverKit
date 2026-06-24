import AppKit
import AVFoundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct Converter {
    let inputURL: URL
    let outputURL: URL
    let startOffset: Double
    let outputSize = CGSize(width: 299, height: 652)
    let fps: Double = 12

    func run() throws {
        let asset = AVURLAsset(url: inputURL)
        let duration = CMTimeGetSeconds(asset.duration)
        let frameCount = max(1, Int(max(1, duration - startOffset) * fps))

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.gif.identifier as CFString,
            frameCount,
            nil
        ) else {
            throw NSError(domain: "VideoToGif", code: 1)
        }

        CGImageDestinationSetProperties(destination, [
            kCGImagePropertyGIFDictionary: [
                kCGImagePropertyGIFLoopCount: 0
            ]
        ] as CFDictionary)

        for frame in 0..<frameCount {
            let seconds = startOffset + Double(frame) / fps
            let image = try generator.copyCGImage(
                at: CMTime(seconds: seconds, preferredTimescale: 600),
                actualTime: nil
            )
            CGImageDestinationAddImage(destination, render(image), [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime: 1 / fps
                ]
            ] as CFDictionary)
        }

        if !CGImageDestinationFinalize(destination) {
            throw NSError(domain: "VideoToGif", code: 2)
        }
    }

    private func render(_ image: CGImage) -> CGImage {
        let inputSize = CGSize(width: image.width, height: image.height)
        let inputAspect = inputSize.width / inputSize.height
        let outputAspect = outputSize.width / outputSize.height

        var crop = CGRect(origin: .zero, size: inputSize)
        if inputAspect > outputAspect {
            crop.size.width = inputSize.height * outputAspect
            crop.origin.x = (inputSize.width - crop.size.width) / 2
        } else {
            crop.size.height = inputSize.width / outputAspect
            crop.origin.y = (inputSize.height - crop.size.height) / 2
        }

        let cropped = image.cropping(to: crop.integral) ?? image
        let context = CGContext(
            data: nil,
            width: Int(outputSize.width),
            height: Int(outputSize.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        context.interpolationQuality = .medium
        context.draw(cropped, in: CGRect(origin: .zero, size: outputSize))
        return context.makeImage()!
    }
}

guard CommandLine.arguments.count >= 3 else {
    fputs("usage: video_to_gif input.mp4 output.gif [start-offset-seconds]\n", stderr)
    exit(64)
}

try Converter(
    inputURL: URL(fileURLWithPath: CommandLine.arguments[1]),
    outputURL: URL(fileURLWithPath: CommandLine.arguments[2]),
    startOffset: CommandLine.arguments.dropFirst(3).first.flatMap(Double.init) ?? 3.0
).run()
