//
//  PEDTVideoProgressEditManager.swift
//  VideoProgressEditDemo
//
//  Created by zjn-apple on 2026/9/14.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit
import AVFoundation
import VideoToolbox

class PEDTVideoProgressEditManager: NSObject {
    var asset: AVAsset?
    func loadVideoSource(asset: AVAsset) {
        self.asset = asset
    }
    
    /// 读取Video视频资源文件完成后Block回调函数
    var readOneFrameToSampleBufferCompletionBlock:((_ sampleBuffer: CMSampleBuffer) -> Void)? = nil
    /// 读取Video视频资源文件并导出CMSampleBuffer视频帧数据流
    func readVideoSource() {
        guard let asset = self.asset else {
            return
        }
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
            self.readOneFrameToSampleBufferCompletionBlock?(sampleBuffer)
            ///
            self.decompressionSampleBufferToPixelBuffer(sampleBuffer: sampleBuffer)
        }
    }
    
    private var decompressionSession: VTDecompressionSession?
    /// 解压CMSampleBuffer完成后Block回调函数
    var decompressionSampleBufferToPixelBufferCompletionBlock:((_ pixelBuffer: CVPixelBuffer) -> Void)? = nil
    /// 解压CMSampleBuffer导出CVPixelBuffer图像数据流
    /// - Parameter sampleBuffer: 视频帧数据流
    func decompressionSampleBufferToPixelBuffer(sampleBuffer: CMSampleBuffer) {
        if self.decompressionSession ==  nil {
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
            self.decompressionSession = PEDTVideoProgressEditHelper.creatDecompressionSession(formatDescription: formatDescription, decompressionOutputCallback: { [weak self] (_, _, status, _, pixelBuffer, pts, _) in
                guard status == noErr,
                      let pixelBuffer = pixelBuffer else {
                    return
                }
                
                kLog("pixelBuffer = \(pixelBuffer)")
                //            self.decompressionSampleBufferToPixelBufferCompletionBlock?(pixelBuffer)
                //                self?.delegate?.decoder(self!, didOutput: pixelBuffer, pts: pts)
            })
        }
        guard let session = self.decompressionSession else {
            return
        }
        
        let flags: VTDecodeFrameFlags = []
        var infoFlags: VTDecodeInfoFlags = []
        VTDecompressionSessionDecodeFrame(session, sampleBuffer: sampleBuffer, flags: flags, frameRefcon: nil, infoFlagsOut: &infoFlags)
    }
}

class PEDTVideoProgressEditHelper: NSObject {
    /// 创建解码器
    static func creatDecompressionSession(formatDescription: CMFormatDescription?, decompressionOutputCallback: VTDecompressionOutputCallback?) -> VTDecompressionSession? {
        guard let formatDescription = formatDescription else {
            return nil
        }
        
        let width = CMVideoFormatDescriptionGetDimensions(formatDescription).width
        let height = CMVideoFormatDescriptionGetDimensions(formatDescription).height
        let pixelBufferAttrs: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
            kCVPixelBufferWidthKey as String: width,
            kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferMetalCompatibilityKey as String: true
        ]
        
        var callback = VTDecompressionOutputCallbackRecord(decompressionOutputCallback: decompressionOutputCallback, decompressionOutputRefCon: nil)
        
        var decompressionSession: VTDecompressionSession?
        let status = VTDecompressionSessionCreate(allocator: kCFAllocatorDefault,
                                                  formatDescription: formatDescription,
                                                  decoderSpecification: nil,
                                                  imageBufferAttributes: pixelBufferAttrs as CFDictionary,
                                                  outputCallback: &callback,
                                                  decompressionSessionOut: &decompressionSession)
        guard status == noErr else {
            print("VTDecompressionSessionCreate failed: \(status)")
            return nil
        }
        
        return decompressionSession
    }
}
