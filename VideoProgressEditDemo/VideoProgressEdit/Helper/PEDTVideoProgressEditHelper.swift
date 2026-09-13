//
//  PEDTVideoProgressEditHelper.swift
//  VideoProgressEditDemo
//
//  Created by zjn-apple on 2026/9/13.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit
import AVFoundation

class PEDTVideoProgressEditHelper: NSObject {
    static func loadVideoSource(asset: AVAsset, readOneFrameCompletion: ((_ sampleBuffer: CMSampleBuffer) -> Void)? = nil) {
        guard let reader = try? AVAssetReader(asset: asset) else {
            return
        }
        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            return
        }
        let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
        reader.add(output)
        reader.startReading()
        
        while reader.status == .reading {
            guard let sampleBuffer = output.copyNextSampleBuffer() else {
                continue
            }
            readOneFrameCompletion?(sampleBuffer)
        }
        
    }
}
