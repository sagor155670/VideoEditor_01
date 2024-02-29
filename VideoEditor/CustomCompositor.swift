//
//  customCompositor.swift
//  VideoEditor
//
//  Created by Saiful Islam Sagor on 19/2/24.
//

import Foundation
import AVFoundation
import VideoToolbox
import SwiftUI


class CustomCompositor: NSObject, AVVideoCompositing {
    
    private var renderContext: AVVideoCompositionRenderContext?
    
    var sourcePixelBufferAttributes: [String : Any]?{
        get{
            return ["\(kCVPixelBufferPixelFormatTypeKey)": kCVPixelFormatType_32BGRA]
        }
    }
    
    var requiredPixelBufferAttributesForRenderContext: [String : Any]{
        get{
            return ["\(kCVPixelBufferPixelFormatTypeKey)" : kCVPixelFormatType_32BGRA]
        }
    }
    
    func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
        renderContext =  newRenderContext
    }
    
    func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
        /* This is where you will process your frames, for each sequence of frame you
         will recieve a render context that supplies a new empty frame , and instructions
         that are assigned to the render context as well*/
        let request = asyncVideoCompositionRequest
        var destinationFrame = request.renderContext.newPixelBuffer()
        print(request.sourceTrackIDs.count)
        let trackId = request.sourceTrackIDs
        print("trackID: \(trackId)")
        
        if request.sourceTrackIDs.count == 2{
            let firstFrame = request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value)
            let secondFrame = request.sourceFrame(byTrackID: request.sourceTrackIDs[1].int32Value)

            let instruction =  request.videoCompositionInstruction
            
        

            if let instr = instruction as? AVVideoCompositionInstruction /*as? CustomOverlayInstruction, let rotate = instr.rotateSecondAsset*/{
                CVPixelBufferLockBaseAddress(firstFrame!, .readOnly)
                CVPixelBufferLockBaseAddress(secondFrame!, .readOnly)
                CVPixelBufferLockBaseAddress(destinationFrame!, CVPixelBufferLockFlags(rawValue: 0))
                for layerinst in instr.layerInstructions{
                    
                }
                var firstImage = createSourceImage(from: firstFrame)
                var secondImage = createSourceImage(from: secondFrame)

                var destWidth =  CVPixelBufferGetWidth(destinationFrame!)
                var destheight = CVPixelBufferGetHeight(destinationFrame!)
                let time = request.compositionTime
                print(time)
//                if time == CMTime(seconds: 10, preferredTimescale: 30){
//                    usleep(1000000)
//                }

//                if rotate{
//                    you can rotate the image however you see fit or need to. You can also attach additional instruction to help you.determine the necessary changes
//                }

                let frame = CGRect(x: 0, y: 0, width: destWidth, height: destheight)
//                This issue might be due to the coordinate system used by Core Animation, which has its origin at the bottom left corner, while the coordinate system used by Core Graphics (which you’re using to draw your image) has its origin at the top left corner. This discrepancy can cause your final image to appear upside down.
                var innerFrame = CGRect(x: 0, y: 0, width: (Double(destWidth) * 0.5), height: (Double(destheight) * 0.5))

                let backgroundLayer = CALayer()
                backgroundLayer.frame = frame
                backgroundLayer.contentsGravity = .resizeAspect
                backgroundLayer.contents = firstImage

                let overlayLayer = CALayer()
                overlayLayer.frame = innerFrame
                overlayLayer.contentsGravity = .resizeAspect
                overlayLayer.contents = secondImage

                let finalLayer =  CALayer()
                finalLayer.frame = frame
                finalLayer.backgroundColor = Color.clear.cgColor
                finalLayer.addSublayer(backgroundLayer)
                finalLayer.addSublayer(overlayLayer)

                //create image using the CALayer
//                let fullImage = imageWithLayer(layer: finalLayer)
                let scale = UIScreen.main.scale
                let width = Int(finalLayer.bounds.width * scale)
                let height = Int(finalLayer.bounds.height * scale)
                
                var gc : CGContext?
                if let destination = destinationFrame, let image = firstImage?.colorSpace{
                    gc =  CGContext(data: CVPixelBufferGetBaseAddress(destination),
                                    width: destWidth, height: destheight,
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(destination),
                                    space: image,
                                    bitmapInfo: secondImage?.bitmapInfo.rawValue ?? 0)
                }
                //draw in the image using CGContext
//                gc?.draw(fullImage, in: frame)
//                finalLayer.transform = CATransform3DMakeRotation(.pi, 1.0, 0.0, 0.0)
                finalLayer.isGeometryFlipped = true
                finalLayer.render(in: gc!)
                gc?.makeImage()

//                make sure you flush the current CALayers , if you fail to,Swift will hold on to them and cause a memory leak
                CATransaction.flush()
                //unlock addresses after finishing
                CVPixelBufferUnlockBaseAddress(destinationFrame!, CVPixelBufferLockFlags(rawValue: 0))
                CVPixelBufferUnlockBaseAddress(firstFrame!, .readOnly)
                CVPixelBufferUnlockBaseAddress(secondFrame!, .readOnly)
                

                //end function with request.finish
                request.finish(withComposedVideoFrame: destinationFrame!)
            }
        }
        else if request.sourceTrackIDs.count == 3{
            let firstFrame = request.sourceFrame(byTrackID: request.sourceTrackIDs[2].int32Value)
            let secondFrame = request.sourceFrame(byTrackID: request.sourceTrackIDs[1].int32Value)
            let thirdFrame = request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value)

            let instruction =  request.videoCompositionInstruction

            if let instr = instruction as? AVVideoCompositionInstruction /*CustomOverlayInstruction, let rotate = instr.rotateSecondAsset*/{
                CVPixelBufferLockBaseAddress(firstFrame!, .readOnly)
                CVPixelBufferLockBaseAddress(secondFrame!, .readOnly)
                CVPixelBufferLockBaseAddress(thirdFrame!, .readOnly)
                CVPixelBufferLockBaseAddress(destinationFrame!, CVPixelBufferLockFlags(rawValue: 0))

                var firstImage = createSourceImage(from: firstFrame)
                var secondImage = createSourceImage(from: secondFrame)
                var thirdImage = createSourceImage(from: thirdFrame)

                var destWidth =  CVPixelBufferGetWidth(destinationFrame!)
                var destheight = CVPixelBufferGetHeight(destinationFrame!)
                let time = request.compositionTime
                print(time)
//                if time == CMTime(seconds: 10, preferredTimescale: 30){
//                    usleep(1000000)
//                }

//                if rotate{
//                    you can rotate the image however you see fit or need to. You can also attach additional instruction to help you.determine the necessary changes
//                }

                let frame = CGRect(x: 0, y: 0, width: destWidth, height: destheight)
//                This issue might be due to the coordinate system used by Core Animation, which has its origin at the bottom left corner, while the coordinate system used by Core Graphics (which you’re using to draw your image) has its origin at the top left corner. This discrepancy can cause your final image to appear upside down.
                var innerFrame = CGRect(x: 0, y: 0, width: (Double(destWidth) * 0.5), height: (Double(destheight) * 0.5))
                var innerFrame2 = CGRect(x: 0, y: (Double(destheight) * 0.5) , width: (Double(destWidth) * 0.5), height: (Double(destheight) * 0.5))

                let backgroundLayer = CALayer()
                backgroundLayer.frame = frame
                backgroundLayer.contentsGravity = .resizeAspect
                backgroundLayer.contents = firstImage

                let overlayLayer = CALayer()
                overlayLayer.frame = innerFrame
                overlayLayer.contentsGravity = .resizeAspect
                overlayLayer.contents = secondImage
                
                let overlayLayer2 = CALayer()
                overlayLayer2.frame = innerFrame2
                overlayLayer2.contentsGravity = .resizeAspect
                overlayLayer2.contents = thirdImage

                let finalLayer =  CALayer()
                finalLayer.frame = frame
                finalLayer.backgroundColor = Color.clear.cgColor
                finalLayer.addSublayer(backgroundLayer)
                finalLayer.addSublayer(overlayLayer)
                finalLayer.addSublayer(overlayLayer2)

                //create image using the CALayer
//                let fullImage = imageWithLayer(layer: finalLayer)
                let scale = UIScreen.main.scale
                let width = Int(finalLayer.bounds.width * scale)
                let height = Int(finalLayer.bounds.height * scale)
                
                var gc : CGContext?
                if let destination = destinationFrame, let image = firstImage?.colorSpace{
                    gc =  CGContext(data: CVPixelBufferGetBaseAddress(destination),
                                    width: destWidth, height: destheight,
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(destination),
                                    space: image,
                                    bitmapInfo: secondImage?.bitmapInfo.rawValue ?? 0)
                }
                //draw in the image using CGContext
//                gc?.draw(fullImage, in: frame)
//                finalLayer.transform = CATransform3DMakeRotation(.pi, 1.0, 0.0, 0.0)
                finalLayer.isGeometryFlipped = true
                finalLayer.render(in: gc!)
                gc?.makeImage()

//                make sure you flush the current CALayers , if you fail to,Swift will hold on to them and cause a memory leak
                CATransaction.flush()
                //unlock addresses after finishing
                CVPixelBufferUnlockBaseAddress(destinationFrame!, CVPixelBufferLockFlags(rawValue: 0))
                CVPixelBufferUnlockBaseAddress(firstFrame!, .readOnly)
                CVPixelBufferUnlockBaseAddress(secondFrame!, .readOnly)
                

                //end function with request.finish
                request.finish(withComposedVideoFrame: destinationFrame!)
            }
        }
//        if request.sourceTrackIDs.count == 2{
//            request.finish(withComposedVideoFrame: request.sourceFrame(byTrackID: request.sourceTrackIDs[1].int32Value)!)
//        }
        else{
            request.finish(withComposedVideoFrame: request.sourceFrame(byTrackID: request.sourceTrackIDs[0].int32Value)!)
        }
        
        
    }
    
    func createSourceImage(from buffer: CVPixelBuffer?) -> CGImage?{
        var image : CGImage?
        VTCreateCGImageFromCVPixelBuffer(buffer!, options: nil, imageOut: &image)
        return image
    }
    
    func imageWithLayer(layer: CALayer) -> CGImage {
        UIGraphicsBeginImageContextWithOptions(layer.bounds.size, layer.isOpaque, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!.cgImage!
    }
    
    
}
