//
//  customInstruction.swift
//  VideoEditor
//
//  Created by Saiful Islam Sagor on 19/2/24.
//

import Foundation
import AVKit

class CustomOverlayInstruction: NSObject, AVVideoCompositionInstructionProtocol{
    
    var timeRange: CMTimeRange
    
    var enablePostProcessing: Bool = true
    
    var containsTweening: Bool = false
    
    var requiredSourceTrackIDs: [NSValue]?
    
    var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
    
    var rotateSecondAsset: Bool?

    
    init(timeRange: CMTimeRange, rotateSceondAsset: Bool) {
        self.timeRange = timeRange
        self.rotateSecondAsset = rotateSceondAsset
    }
    
}
