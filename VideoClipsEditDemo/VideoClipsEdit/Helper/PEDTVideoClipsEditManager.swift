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
    let audioSettings = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: 44100.0,
        AVNumberOfChannelsKey: 2,
        AVLinearPCMBitDepthKey: 32,
        AVLinearPCMIsFloatKey: true,
        AVLinearPCMIsBigEndianKey: false
    ] as [String : Any]
    
    let videoSettings = [
        kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ] as [String : Any]
    
    var asset: AVAsset?
    func loadVideoSource(asset: AVAsset) {
        self.asset = asset
    }
    /// 视频帧率
    var fps = 0.0 as Float
    /// 视频帧Model数据模型的流数组
    var videoFrameModels = [PEDTVideoFrameModel]()
    func getIndexOfVideoFrameModel(pts: CMTime) -> Int {
        for index in self.videoFrameModels.indices {
            let videoFrameModel = self.videoFrameModels[index]
            if (pts == videoFrameModel.pts) {
                return index
            }
        }
        
        return -1
    }


    
    func readVideoSourceDecodeToPixelAndPcm(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]) -> Void)? = nil) {
        self.readVideoSourceAndDecodeToPixelBuffer { [weak self] videoFrameModels in
            guard let self = self else {
                return
            }
            
            self.readVideoSourceAndDecodeToPcm { [weak self] videoFrameModels in
                guard let self = self else {
                    return
                }
                
                completionCallback?(self.videoFrameModels)
            }
        }
    }
    
    /// 读取Video视频资源并且Decode解码视频帧
    func readVideoSourceAndDecodeToPixelBuffer(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            guard let asset = self.asset else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            
            self.fps = videoTrack.nominalFrameRate
            
            let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: self.videoSettings)
            guard assetReader.canAdd(videoOutput) else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            assetReader.add(videoOutput)
            assetReader.startReading()
            
            self.videoFrameModels.removeAll()
            while (.reading == assetReader.status) {
                guard let sampleBuffer = videoOutput.copyNextSampleBuffer() else {
                    continue
                }
                guard CMSampleBufferIsValid(sampleBuffer) else {
                    continue
                }
                guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                    continue
                }
                let pixelBuffer = imageBuffer as CVPixelBuffer
                let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let duration = CMSampleBufferGetDuration(sampleBuffer)
                
                let videoFrameModel = PEDTVideoFrameModel(pixelBuffer: pixelBuffer, pts: pts, duration: duration)
                self.videoFrameModels.append(videoFrameModel)
            }

            if (.completed == assetReader.status) {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
            }

        }
    }
    
    /// 视频解码器
    private var decompressionSession: VTDecompressionSession?
    /// 读取Video视频资源,并且Decompression解码视频帧数据
    func readVideoSourceAndDecompressionToPixelBuffer(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            guard let asset = self.asset else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            self.fps = videoTrack.nominalFrameRate
            
            let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: self.videoSettings)
            guard assetReader.canAdd(videoOutput) else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            assetReader.add(videoOutput)
            assetReader.startReading()
            
            self.decompressionSession = nil
            self.videoFrameModels.removeAll()
            while (.reading == assetReader.status) {
                guard let sampleBuffer = videoOutput.copyNextSampleBuffer() else {
                    continue
                }
                guard CMSampleBufferIsValid(sampleBuffer) else {
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

            if (.completed == assetReader.status) {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
            }

        }
    }
    
    func readVideoSourceAndDecodeToPcm(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            guard let asset = self.asset else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: self.audioSettings)
            guard assetReader.canAdd(audioOutput) else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            assetReader.add(audioOutput)
            assetReader.startReading()
            
            while (.reading == assetReader.status) {
                guard let sampleBuffer = audioOutput.copyNextSampleBuffer() else {
                    continue
                }
                guard CMSampleBufferIsValid(sampleBuffer) else {
                    continue
                }
                guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
                    continue
                }
                var length = 0
                var outputData: UnsafeMutablePointer<Int8>?
                CMBlockBufferGetDataPointer(blockBuffer,
                                           atOffset: 0,
                                           lengthAtOffsetOut: nil,
                                           totalLengthOut: &length,
                                           dataPointerOut: &outputData)
                guard let bytes = outputData else {
                    continue
                }
                let pcm = Data(bytes: bytes, count: length)
                let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let index = self.getIndexOfVideoFrameModel(pts: pts)
                guard index != -1 else {
                    continue
                }
                
                var videoFrameModel = self.videoFrameModels[index]
                videoFrameModel.pcmData = pcm
                videoFrameModel.audioFormat = AVAudioFormat(settings: self.audioSettings)
            }

            if (.completed == assetReader.status) {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
            }

        }
    }
    
    func audioDecode(sampleBuffer: CMSampleBuffer) -> PEDTAudioFrameModel? {
        let mBuffers = AudioBuffer(mNumberChannels: 0,mDataByteSize: 0,mData: nil)
        var audioBufferList = AudioBufferList(mNumberBuffers: 1, mBuffers: mBuffers)
        var blockBuffer: CMBlockBuffer?
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, bufferListSizeNeededOut: nil,
                                                                             bufferListOut: &audioBufferList,
                                                                             bufferListSize: MemoryLayout<AudioBufferList>.size,
                                                                             blockBufferAllocator: nil,
                                                                             blockBufferMemoryAllocator: nil,
                                                                             flags: 0,
                                                                             blockBufferOut: &blockBuffer
        )
        guard status == noErr, blockBuffer != nil else {
            return nil
        }
        
        // 拷贝 PCM 数据
        let audioBuffer = audioBufferList.mBuffers
        guard let audioBufferData = audioBuffer.mData else {
            return nil
        }
        let pcmData = Data(bytes: audioBufferData, count: Int(audioBuffer.mDataByteSize))
        let audioFrame = PEDTAudioFrameModel(pcmData: pcmData, sampleRate: 44100, channels: 2, pts: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        return audioFrame
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
            // ---- Video Input ----
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
            
            // ---- Audio Input ----
            let audioInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: 44100,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderBitRateKey: 128000
                ]
            )
            assetWriter.add(audioInput)
            
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
    
/// 视频帧数据Model模型
struct PEDTVideoFrameModel {
    /// PixelBuffer图形数据流
    var pixelBuffer: CVPixelBuffer
    /// PCM音频数据流
    var pcmData: Data?
    /// 音频格式(包括sampleRate采样率, channel音频通道数等参数)
    var audioFormat: AVAudioFormat?
    
    /// 视频时间戳
    let pts: CMTime
    /// 总时长
    let duration: CMTime
}

/// 音频帧eModel数据模型
struct PEDTAudioFrameModel {
    /// 音频流数据
    var pcmData: Data
    /// 音频采样率
    let sampleRate: Double
    /// 音频通道数
    let channels: UInt32
    /// 音频时间戳
    let pts: CMTime
}
