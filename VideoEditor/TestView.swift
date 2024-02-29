    //
    //  TestView.swift
    //  VideoEditor
    //
    //  Created by Saiful Islam Sagor on 19/2/24.
    //

import SwiftUI
import AVKit
import AVFoundation

struct TestView: View {
    @State var composition = AVMutableComposition()
    @State var playerItem: AVPlayerItem?
    @State var player: AVPlayer?
    @State var videoComposition: AVMutableVideoComposition?
    @State var isReady:Bool = false
    var body: some View {
        VStack{
            if isReady{
                HStack{
                    Button{
                        manipulateTrack(duration: CMTimeMake(value: 150, timescale: 30), trackID: 1)
                            //                            playerItem?.videoComposition = videoComposition
                            //                        playerItem?.seekingWaitsForVideoCompositionRendering = true
                            //                        videoComposition?.customVideoCompositorClass = CustomCompositor.self
                            //                        player?.replaceCurrentItem(with: playerItem)
                    }label: {
                        Text("Duration++")
                            .font(.callout)
                            .fontWeight(.heavy)
                    }
                    
                    Button{
                            //                        addTrack()
                    }label: {
                        Text("add track")
                            .font(.callout)
                            .fontWeight(.heavy)
                    }
                }
                VideoPlayer(player: self.player)
                    .frame(width: 300,height: 250)
            }
            Button{
                composer()
                self.isReady.toggle()
            }label: {
                Text("start")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .frame(width: 100 , height: 50)
            }
            
        }
        .onChange(of: composition) { oldValue, newValue in
                //            let currentTime = playerItem?.currentTime()
                //            self.player!.replaceCurrentItem(with: newValue)
                //            self.playerItem = AVPlayerItem(asset: newValue)
                //            self.player!.replaceCurrentItem(with: playerItem)
            
                //            self.player!.seek(to: currentTime!, toleranceBefore: .zero, toleranceAfter: .zero)
        }
    }
    
    func manipulateTrack( duration: CMTime, trackID: CMPersistentTrackID) {
        let emptyAsset = AVAsset(url: Bundle.main.url(forResource: "60fps", withExtension: ".mp4")!)
        let emptyTrack =  emptyAsset.tracks(withMediaType: .video).first!
        
        
        do{
            guard let track = composition.track(withTrackID: trackID) else{
                return
            }
            let timerange = track.timeRange
            track.removeTimeRange(timerange)
            try track.insertTimeRange(CMTimeRangeMake(start: .zero, duration: CMTimeAdd(timerange.duration, duration) ), of: emptyTrack, at: .zero)
            
                //            let instruction = CustomOverlayInstruction(timeRange: CMTimeRange(start: .zero, duration: composition.duration), rotateSceondAsset: true)
            let instruction = AVMutableVideoCompositionInstruction()
            for trck in composition.tracks{
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trck)
                layerInstruction.setCropRectangle(CGRect(x: 0, y: 0, width: 200, height: 150), at: .zero)
                instruction.layerInstructions.append(layerInstruction)
            }
            
            instruction.enablePostProcessing = true
            instruction.timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)
            
            
            let videoSize = track.naturalSize
            
                //            videoComposition?.customVideoCompositorClass = CustomCompositor.self
            videoComposition?.instructions = [instruction]
            videoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30)
            videoComposition?.renderSize = videoSize
                //
            playerItem = AVPlayerItem(asset: composition)
            playerItem?.videoComposition = videoComposition
            playerItem!.seekingWaitsForVideoCompositionRendering = true
                //
            player?.replaceCurrentItem(with: playerItem)
            player?.play()
            
        }catch{
            print(error.localizedDescription)
        }
        
            //    try track1?.insertEmptyTimeRange(CMTimeRangeMake(start: .zero, duration: CMTimeMake(value: 50, timescale: 1)))
        
    }
    
        //    func createCustomTrack(for Composition: AVMutableComposition,ofType trackType:AVMediaType, from track: AVAssetTrack, with sourceInfo: [String : Double]) -> CMPersistentTrackID {
        //        let blankAsset = AVAsset(url: Bundle.main.url(forResource: "60fps", withExtension: ".mp4")!)
        //        let blankTrack = blankAsset.tracks(withMediaType: .video).first!
        //
        //        guard let customTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)else{
        //            return -1
        //        }
        //        do {
        //           try customTrack.insertTimeRange(blankTrack.timeRange, of: blankTrack, at: .zero)
        //
        //            if duration != blankTrack.timeRange.duration {
        //                customTrack.scaleTimeRange(blankTrack.timeRange, toDuration: duration)
        //            }
        //        }catch{
        //            print(error.localizedDescription)
        //        }
        //        return customTrack.trackID
        //    }
    
    func createTrack(for Composition: AVMutableComposition,ofType trackType:AVMediaType? , _ assetTrack: AVAssetTrack, withSourceInfo sourceInfo: [String : Any]) -> CMPersistentTrackID {
        
        guard let newTrack = Composition.addMutableTrack(withMediaType: trackType ?? .video , preferredTrackID: kCMPersistentTrackID_Invalid) else {return -1}
        
        let activationTime = CMTime(value: CMTimeValue(sourceInfo["ActivationTime"] as? CMTimeValue ?? 0 ), timescale: 1000000)
        let trimStart = CMTime(value: CMTimeValue(sourceInfo["TrimStart"] as? CMTimeValue ?? 0 ), timescale: 1000000)
        let trimEnd = CMTime(value: CMTimeValue(sourceInfo["TrimEnd"] as? CMTimeValue ?? Int64(assetTrack.timeRange.duration.seconds) ), timescale: 1000000)
        let trimmedTimerange = CMTimeRange(start: trimStart, end: trimEnd)
        
        do{
            if trackType == nil {
                try newTrack.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: activationTime)
                newTrack.scaleTimeRange(newTrack.timeRange, toDuration: trimmedTimerange.duration)
            }else{
                try newTrack.insertTimeRange(trimmedTimerange, of: assetTrack, at: activationTime)
            }
        }catch{
            print(error.localizedDescription)
        }
        
        return newTrack.trackID
    }
    
    func deleteTrack(trackId Id:CMPersistentTrackID ,of Composition: AVMutableComposition ){
        guard let compositionTrack = Composition.track(withTrackID: Id) else{
            print("No track available with trackId: \(Id)")
            return
        }
        Composition.removeTrack(compositionTrack)
    }
    
    func ReplaceTrack(of Composition: AVMutableComposition ,with trackId: CMPersistentTrackID, newTrack assetTrack: AVAssetTrack, ofType trackType:AVMediaType?, with sourceInfo: [String : Any] ) -> CMPersistentTrackID {
        guard let trackToRemove = Composition.track(withTrackID: trackId) else{
            print(print("No track found with trackId: \(trackId)"))
            return -1
        }
        Composition.removeTrack(trackToRemove)
        
        guard let newTrack = Composition.addMutableTrack(withMediaType: trackType ?? .video , preferredTrackID: kCMPersistentTrackID_Invalid) else {return -1}
        
        let activationTime = CMTime(value: CMTimeValue(sourceInfo["ActivationTime"] as? CMTimeValue ?? 0 ), timescale: 1000000)
        let trimStart = CMTime(value: CMTimeValue(sourceInfo["TrimStart"] as? CMTimeValue ?? 0 ), timescale: 1000000)
        let trimEnd = CMTime(value: CMTimeValue(sourceInfo["TrimEnd"] as? CMTimeValue ?? Int64(assetTrack.timeRange.duration.seconds) ), timescale: 1000000)
        let trimmedTimerange = CMTimeRange(start: trimStart, end: trimEnd)
        
        do{
            if trackType == nil {
                try newTrack.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: activationTime)
                newTrack.scaleTimeRange(newTrack.timeRange, toDuration: trimmedTimerange.duration)
            }else{
                try newTrack.insertTimeRange(trimmedTimerange, of: assetTrack, at: activationTime)
            }
        }catch{
            print(error.localizedDescription)
        }
        return newTrack.trackID
    }
    
    func updateTrack(with trackId: CMPersistentTrackID,ofType trackType:AVMediaType?,_ Composition: AVMutableComposition,_ assetTrack: AVAssetTrack, _ sourceInfo: [String : Any]){
        guard let trackToUpdate  = Composition.track(withTrackID: trackId) else{
            print("No tracks available with trackId: \(trackId)")
            return
        }
        
        let activationTime = CMTime(value: CMTimeValue(sourceInfo["ActivationTime"] as? CMTimeValue ?? 0 ), timescale: 1000000)
        let trimStart = CMTime(value: CMTimeValue(sourceInfo["TrimStart"] as? CMTimeValue ?? 0 ), timescale: 1000000)
        let trimEnd = CMTime(value: CMTimeValue(sourceInfo["TrimEnd"] as? CMTimeValue ?? Int64(assetTrack.timeRange.duration.seconds) ), timescale: 1000000)
        let trimmedTimerange = CMTimeRange(start: trimStart, end: trimEnd)
        
        trackToUpdate.removeTimeRange(trackToUpdate.timeRange)
        
        do{
            if trackType == nil {
                try trackToUpdate.insertTimeRange(assetTrack.timeRange, of: assetTrack, at: activationTime)
                trackToUpdate.scaleTimeRange(trackToUpdate.timeRange, toDuration: trimmedTimerange.duration)
            }else{
                try trackToUpdate.insertTimeRange(trimmedTimerange, of: assetTrack, at: activationTime)
            }
        }catch{
            print(error.localizedDescription)
        }
        
    }
    
    func updateComposition(composition: AVMutableComposition, _ sourceInfos: [[String : Any]]){
        for sourceInfo in sourceInfos {
            let trackId = CMPersistentTrackID(sourceInfo["Id"] as? CMPersistentTrackID ?? -1 )
            guard let track = composition.track(withTrackID: trackId) else{
                print("No tracks available with trackId: \(trackId)")
                return
            }
            let activationTime = CMTime(value: CMTimeValue(sourceInfo["ActivationTime"] as? CMTimeValue ?? 0 ), timescale: 1000000)
            let timerange = track.timeRange
            track.removeTimeRange(timerange)
            do{
                try track.insertTimeRange(timerange, of: sourceInfo["assetTrack"] as! AVAssetTrack , at: activationTime)
            }catch{
                print(error.localizedDescription)
            }
                        
            
        }
    }
    
    
        //    func addTrack(){
        //       let customTrackId = createCustomTrack(for: composition, ofDuration: CMTime(value: 10, timescale: 1))
        //
        //        let instruction = AVMutableVideoCompositionInstruction()
        //        for trck in composition.tracks{
        //            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: trck)
        ////            layerInstruction.setCropRectangle(CGRect(x: 0, y: 0, width: 200, height: 150), at: .zero)
        //            instruction.layerInstructions.append(layerInstruction)
        //        }
        //
        //        instruction.enablePostProcessing = true
        //        instruction.timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)
        ////        let videoSize = customTrack.naturalSize
        //
        ////            videoComposition?.customVideoCompositorClass = CustomCompositor.self
        //        videoComposition?.instructions = [instruction]
        //        videoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30)
        //        videoComposition?.renderSize = composition.naturalSize
        ////
        //        playerItem = AVPlayerItem(asset: composition)
        //        playerItem?.videoComposition = videoComposition
        //        playerItem!.seekingWaitsForVideoCompositionRendering = true
        ////
        //        player?.replaceCurrentItem(with: playerItem)
        //        player?.play()
        //    }
    func composer(){
        let videoAsset1 = AVAsset(url:  Bundle.main.url(forResource: "60fps", withExtension: "mp4")!)
        let videoAsset2 = AVAsset(url:  Bundle.main.url(forResource: "30fps", withExtension: "mp4")!)
        let audioAsset = AVAsset(url:  Bundle.main.url(forResource: "mono", withExtension: "m4a")!)
        
        guard let track1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let track2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let track3 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
        else {
            return
        }
        print(track3.trackID)
        
        guard let vTrack1 = videoAsset1.tracks(withMediaType: .video).first
                ,let vTrack2 = videoAsset2.tracks(withMediaType: .video).first
                ,let aTrack = audioAsset.tracks(withMediaType: .audio).first
        else{
            return
        }
        do{
            try track1.insertTimeRange(CMTimeRange(start: .zero, duration: CMTime(value: 5, timescale: 1)) , of: vTrack1, at: .zero)
            try track1.insertTimeRange(CMTimeRange(start: .zero , duration: CMTime(value: 5, timescale: 1)), of: vTrack2, at: CMTime(value: 10, timescale: 1) )
            try track1.insertTimeRange(CMTimeRange(start: .zero , duration: CMTime(value: 11, timescale: 1)), of: vTrack1, at: CMTime(value: 13, timescale: 1))
            try track3.insertTimeRange(aTrack.timeRange, of: aTrack, at: CMTime(value: 5, timescale: 1))
            
                //            track1.scaleTimeRange(CMTimeRange(start: vTrack2.timeRange.duration, duration: vTrack1.timeRange.duration), toDuration: CMTimeMake(value: 10, timescale: 1))
            
                //            let instruction = AVMutableVideoCompositionInstruction()
            
                //            let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track1)
                //            let layerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: track2)
                //            layerInstruction2.setOpacity(0, at: track2.timeRange.duration)
                //            instruction.layerInstructions = [layerInstruction/*,layerInstruction2*/]
            let instruction = CustomOverlayInstruction(timeRange: CMTimeRange(start: .zero, duration: composition.duration), rotateSceondAsset: true)
            instruction.timeRange = CMTimeRangeMake(start: .zero, duration: composition.duration)
            
                // Here we can set the transform to display videos side by side
            let videoSize = track1.naturalSize
            
            videoComposition = AVMutableVideoComposition()
            videoComposition?.customVideoCompositorClass = CustomCompositor.self
            videoComposition?.instructions = [instruction]
            videoComposition?.frameDuration = CMTimeMake(value: 1, timescale: 30)
            videoComposition?.renderSize = videoSize
            
            playerItem = AVPlayerItem(asset: composition)
            playerItem?.videoComposition = videoComposition
            self.player = AVPlayer(playerItem: playerItem)
            player?.allowsExternalPlayback = true
            player?.play()
        }catch{
            print("Error with \(error.localizedDescription)")
        }
        
        
        
    }
}



    //#Preview {
    //    TestView()
    //}
