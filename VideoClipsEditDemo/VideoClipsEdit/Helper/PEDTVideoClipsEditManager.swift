//
//  PEDTVideoClipsEditManager.swift
//  VideoClipsEditDemo
//
//  Created by zjn-apple on 2026/9/14.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit
import AVFoundation
import VideoToolbox

class PEDTVideoClipsEditManager: NSObject {
    var asset: AVAsset?
    func loadVideoSource(asset: AVAsset) {
        self.asset = asset
    }
    
    /// 视频帧Model数据模型的流数组
    var videoFrameModels = [PEDTVideoFrameModel]()
    /// 视频帧率
    var fps = 0.0 as Float
    
    /// 视频解码器
    private var decompressionSession: VTDecompressionSession?
    /// 读取Video视频资源,并且Decompression解码视频帧数据
    func readVideoSourceAndDecompression(decompressionCompletionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            guard let asset = self.asset else {
                return
            }
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                return
            }
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                return
            }
            self.fps = videoTrack.nominalFrameRate
            
            let output = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
            assetReader.add(output)
            assetReader.startReading()
            
            self.decompressionSession = nil
            self.videoFrameModels.removeAll()
            while assetReader.status == .reading {
                guard let sampleBuffer = output.copyNextSampleBuffer() else {
                    continue
                }
                if self.decompressionSession ==  nil {
                    let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
                    /*
                     decompressionOutputCallback : 视频帧解码完成后的Callback回调函数
                     */
                    self.decompressionSession = PEDTVideoClipsEditHelper.creatDecompressionSession(formatDescription: formatDescription, target: self, decompressionOutputCallback: { (outputRefCon, sourceFrameRefCon, status, infoFlags, imageBuffer, pts, duration) in
                        guard status == noErr,
                              let imageBuffer = imageBuffer,
                              let refCon = outputRefCon else {
                            return
                        }
                        // 把 void* 转回 Swift 对象
                        let manager = Unmanaged<PEDTVideoClipsEditManager>.fromOpaque(refCon).takeUnretainedValue()
                        let pixelBuffer = imageBuffer as CVPixelBuffer
                        manager.videoFrameModels.append(PEDTVideoFrameModel(pixelBuffer: pixelBuffer, pts: pts, duration: duration))
                    })
                }
                guard let session = self.decompressionSession else {
                    continue
                }
                
                let flags: VTDecodeFrameFlags = []
                var infoFlags: VTDecodeInfoFlags = []
                VTDecompressionSessionDecodeFrame(session, sampleBuffer: sampleBuffer, flags: flags, frameRefcon: nil, infoFlagsOut: &infoFlags)
            }

            DispatchQueue.main.async {
                decompressionCompletionCallback?(self.videoFrameModels)
            }
        }
    }
    
    
    /// 导出视频资源
    /// - Parameter outputURL: 输出视频资源的路径
    func exportVideoSource(outputURL: URL, exportCompletionCallback: ((_ outputPath: URL?) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            let videoSourcePath = outputURL.path
            if (FileManager.default.fileExists(atPath: videoSourcePath) == true) {
                do {
                    try FileManager.default.removeItem(atPath: videoSourcePath)
                } catch {
                    print("FileManager.default.removeItem操作失败")
                }
            }
            
            guard let firstFrameModel = self.videoFrameModels.first else {
                exportCompletionCallback?(nil)
                return
            }
            let width = CVPixelBufferGetWidth(firstFrameModel.pixelBuffer)
            let height = CVPixelBufferGetHeight(firstFrameModel.pixelBuffer)
            let pixelFormat = CVPixelBufferGetPixelFormatType(firstFrameModel.pixelBuffer)
            
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
                exportCompletionCallback?(nil)
                return
            }
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: width,
                AVVideoHeightKey: height,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: width * height * 2, // 按需调
                    AVVideoExpectedSourceFrameRateKey: self.fps,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
                ]
            ]
            
            let videoInput = AVAssetWriterInput(
                mediaType: .video,
                outputSettings: videoSettings
            )
            videoInput.expectsMediaDataInRealTime = false
            
            let adaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoInput,
                sourcePixelBufferAttributes: [
                    kCVPixelBufferPixelFormatTypeKey as String: pixelFormat,
                    kCVPixelBufferWidthKey as String: width,
                    kCVPixelBufferHeightKey as String: height,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:] // 真机必须
                ]
            )
            
            assetWriter.add(videoInput)
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            DispatchQueue.main.async {
                var frameIndex = 0
                videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "\(Self.self)_\(#function)_requestMediaDataWhenReady()")) { [weak videoInput] in
                    guard let videoInput = videoInput else {
                        return
                    }
                    while videoInput.isReadyForMoreMediaData {
                        if (frameIndex >= self.videoFrameModels.count) {
                            videoInput.markAsFinished()
                            assetWriter.finishWriting {
                                if assetWriter.status == .completed {
                                    DispatchQueue.main.async {
                                        exportCompletionCallback?(outputURL)
                                    }
                                } else if let error = assetWriter.error {
                                    DispatchQueue.main.async {
                                        exportCompletionCallback?(outputURL)
                                    }
                                    print("写入失败 ❌", error, videoSourcePath)
                                }
                            }
                            return
                        }
                        
                        let videoFrameModel = self.videoFrameModels[frameIndex]
                        let timescale: CMTimeScale = CMTimeScale(self.fps)
                        let pts = CMTime(
                            value: Int64(frameIndex),
                            timescale: timescale
                        )
                        
                        let isSuccess = adaptor.append(videoFrameModel.pixelBuffer, withPresentationTime: pts)
                        if (isSuccess == false) {
                            videoInput.markAsFinished()
                            assetWriter.finishWriting {
                                if assetWriter.status == .completed {
                                    DispatchQueue.main.async {
                                        exportCompletionCallback?(outputURL)
                                    }
                                } else if let error = assetWriter.error {
                                    DispatchQueue.main.async {
                                        exportCompletionCallback?(outputURL)
                                    }
                                    print("写入失败 ❌", error, videoSourcePath)
                                }
                            }
                            return
                        }
                        frameIndex = frameIndex + 1
                    }
                }
            }
        }
    }
    
}

/// 视频进度帧编辑Helper助手类
class PEDTVideoClipsEditHelper: NSObject {
    /// 创建视频解码器
    /// - Parameters:
    ///   - formatDescription: 创建视频解码器
    ///   - decompressionOutputCallback: 视频解码成功后的回调
    ///   - target: 需要回调结果的对象, 一般是self
    /// - Returns:视频解码器对象
    static func creatDecompressionSession(formatDescription: CMFormatDescription?, target: NSObject, decompressionOutputCallback: VTDecompressionOutputCallback?) -> VTDecompressionSession? {
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
        
        // 把 self 转成 void*
        let refCon = UnsafeMutableRawPointer(
            Unmanaged.passUnretained(target).toOpaque()
        )
        var callback = VTDecompressionOutputCallbackRecord(decompressionOutputCallback: decompressionOutputCallback, decompressionOutputRefCon: refCon)
        
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
    
    static func imageWithPixelBuffer(pixelBuffer: CVPixelBuffer) -> UIImage? {
        var cgImage: CGImage?
        let status = VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        guard status == noErr,
        let resultCGImage = cgImage else {
            return nil
        }
        let resultImage = UIImage(cgImage: resultCGImage)
        return resultImage
    }
    
    // MARK: - 复用！别每次 new
    private static let keyContext: CIContext = {
        // 指定 Metal device，确保走 GPU
        let opts: [CIContextOption: Any] = [
            .useSoftwareRenderer: false,
            .cacheIntermediates: false   // 不缓存中间节点，省内存
        ]
        return CIContext(options: opts)
    }()
    /// 缩放PixelBuffer图形对象并返回UIImage对象
    /// - Parameters:
    ///   - inputPixelBuffer: 输入PixelBuffer图形对象
    ///   - width: 缩放后的宽
    ///   - height: 缩放后的高
    ///   - contentMode: 填充模式
    /// - Returns: UIImage对象
    static func resizePixelBufferToImage(inputPixelBuffer: CVPixelBuffer, width: Int, height: Int, contentMode: UIView.ContentMode = .scaleAspectFill) -> UIImage? {
        let coreImage = CIImage(cvPixelBuffer: inputPixelBuffer)
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(inputPixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(inputPixelBuffer))
        
        let scaleX = CGFloat(width) / pixelBufferWidth
        let scaleY = CGFloat(height) / pixelBufferHeight
        
        var scale = 1.0 as CGFloat
        switch contentMode {
        case .scaleAspectFill: scale = max(scaleX, scaleY)
            break
        case .scaleAspectFit:  scale = min(scaleX, scaleY)
            break
        default:
            break
        }

        var scaledCoreImage = coreImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        if (.scaleToFill == contentMode) {
            scaledCoreImage = coreImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        }
        
        // 2) 裁剪到目标尺寸（居中）
        let scaledImageWidth = scaledCoreImage.extent.width
        let scaledImageHeight = scaledCoreImage.extent.height
        let cropX = (scaledImageWidth - CGFloat(width)) / 2
        let cropY = (scaledImageHeight - CGFloat(height)) / 2
        let croppedCoreImage = scaledCoreImage.cropped(to: CGRect(x: cropX, y: cropY,
                                                 width: CGFloat(width),
                                                 height: CGFloat(height)))
        guard let cgImage = keyContext.createCGImage(croppedCoreImage, from: croppedCoreImage.extent) else {
            return nil
        }
        
        let resultImage = UIImage(cgImage: cgImage)
        return resultImage
    }
    /// 缩放PixelBuffer图形对象
    /// - Parameters:
    ///   - inputPixelBuffer: 输入PixelBuffer图形对象
    ///   - width: 缩放后的宽
    ///   - height: 缩放后的高
    ///   - contentMode: 填充模式
    /// - Returns: PixelBuffer图形对象
    static func resizePixelBuffer(inputPixelBuffer: CVPixelBuffer, width: Int, height: Int, contentMode: UIView.ContentMode = .scaleAspectFill) -> CVPixelBuffer? {
        let coreImage = CIImage(cvPixelBuffer: inputPixelBuffer)
        let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(inputPixelBuffer))
        let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(inputPixelBuffer))
        
        let scaleX = CGFloat(width) / pixelBufferWidth
        let scaleY = CGFloat(height) / pixelBufferHeight
        
        var scale = 1.0 as CGFloat
        switch contentMode {
        case .scaleAspectFill: scale = max(scaleX, scaleY)
            break
        case .scaleAspectFit:  scale = min(scaleX, scaleY)
            break
        default:
            break
        }

        var scaledCoreImage = coreImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        if (.scaleToFill == contentMode) {
            scaledCoreImage = coreImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
        }
        
        // 2) 裁剪到目标尺寸（居中）
        let scaledImageWidth = scaledCoreImage.extent.width
        let scaledImageHeight = scaledCoreImage.extent.height
        let cropX = (scaledImageWidth - CGFloat(width)) / 2
        let cropY = (scaledImageHeight - CGFloat(height)) / 2
        var croppedCoreImage = scaledCoreImage.cropped(to: CGRect(x: cropX, y: cropY,
                                                 width: CGFloat(width),
                                                 height: CGFloat(height)))
        let tx = -croppedCoreImage.extent.origin.x
        let ty = -croppedCoreImage.extent.origin.y
        croppedCoreImage = croppedCoreImage.transformed(by: CGAffineTransform(translationX: tx, y: ty))
        // 3) 创建目标 buffer —— 用 Metal 兼容格式
        var outputPixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        let status = CVPixelBufferCreate(
            nil,
            width, height,
            kCVPixelFormatType_32BGRA,   // 或保持原格式
            attrs as CFDictionary,
            &outputPixelBuffer
        )
        guard status == kCVReturnSuccess, let outputPixelBuffer else {
            return nil
        }
        // 4) GPU render —— 关键：用共享的 CIContext，别每次创建
        keyContext.render(croppedCoreImage, to: outputPixelBuffer)
        return outputPixelBuffer
    }
    
    static func greyRenderPixelBuffer(inputPixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let inputCoreImage = CIImage(cvPixelBuffer: inputPixelBuffer)
        guard let filter = CIFilter(name: "CIColorControls") else {
            return nil
        }
        filter.setValue(inputCoreImage, forKey: kCIInputImageKey)
//        filter.setValue(0.0, forKey: kCIInputBrightnessKey)
//        filter.setValue(0.0, forKey: kCIInputContrastKey)
        filter.setValue(0.0, forKey: kCIInputSaturationKey)
        
        guard let outputCoreImage = filter.outputImage else {
            return nil
        }
        
        // 3) 创建目标 buffer —— 用 Metal 兼容格式
        var outputPixelBuffer: CVPixelBuffer?
        let attrs: [String: Any] = [
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        let status = CVPixelBufferCreate(
            nil,
            Int(inputCoreImage.extent.width), Int(inputCoreImage.extent.height),
            kCVPixelFormatType_32BGRA,   // 或保持原格式
            attrs as CFDictionary,
            &outputPixelBuffer
        )
        guard status == kCVReturnSuccess, let outputPixelBuffer else {
            return nil
        }
        // 4) GPU render —— 关键：用共享的 CIContext，别每次创建
        keyContext.render(outputCoreImage, to: outputPixelBuffer)
        return outputPixelBuffer
    }
}

struct PEDTVideoFrameModel {
    /// 图像数据流
    var pixelBuffer: CVPixelBuffer
    /// 视频时间戳
    let pts: CMTime
    /// 总时长
    let duration: CMTime
}
