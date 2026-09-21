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

/**
 一般音频采样率为44100.0
 iPhone拍摄视频一般是48000.0
 */
let kAudioSampleRate = 44100.0
class PEDTVideoClipsEditManager: NSObject {
    var audioStreamBasicDescription: AudioStreamBasicDescription?
    var videoAsset: AVAsset?
    func loadVideoSource(asset: AVAsset) {
        self.videoAsset = asset
    }
    /// 视频帧率
    var fps = 0.0 as Float
    /// 视频帧Model数据模型的流数组
    var videoFrameModels = [PEDTVideoFrameModel]()
    /// 音频帧Model数据模型的流数组
    var audioFrameModels = [PEDTAudioFrameModel]()
    
    func readVideoSourceDecodeToPixelAndPcm(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel], _ audioFrameModels: [PEDTAudioFrameModel]) -> Void)? = nil) {
        self.readVideoSourceAndDecompressionToPixelBuffer { [weak self] videoFrameModels in
            guard let self = self else {
                return
            }
            self.readVideoSourceAndDecodeToAudioPcm { [weak self] audioFrameModels in
                guard let self = self else {
                    return
                }
                
                completionCallback?(self.videoFrameModels, self.audioFrameModels)
            }
        }
    }
    
    /// 视频解码器
    private var decompressionSession: VTDecompressionSession?
    /// 自定义解码器Decompression进行视频解码
    func readVideoSourceAndDecompressionToPixelBuffer(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            guard let asset = self.videoAsset else {
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
            
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: nil)
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
            
            if (.completed == assetReader.status ||
                .failed == assetReader.status ||
                .cancelled == assetReader.status) {
                DispatchQueue.main.async {
                    /*
                     VTDecompressionSessionDecodeFrame是异步解码
                     所以数组插入顺序不是时间序列顺序
                     所以需要对象视频帧数组进行重新排序
                     */
                    self.videoFrameModels.sort { videoFrameModelA, videoFrameModelB in
                        if videoFrameModelA.pts.value > videoFrameModelB.pts.value {
                            return false
                        } else {
                            return true
                        }
                    }
                    completionCallback?(self.videoFrameModels)
                }
            }
            
        }
    }
    /// 系统解码器进行视频解码(会使用兼容性最强的32BGRA格式进行解码,所以内存占用会特别大)
    func readVideoSourceAndDecodeToPixelBuffer(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            guard let asset = self.videoAsset else {
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
            
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
                return
            }
            
            let videoReaderSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ] as [String : Any]
            let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: videoReaderSettings)
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
                /*
                 官方建议不要直接将CMSampleBufferGetImageBuffer获取到的Buffer赋值到内存变量中
                 而是通过CVPixelBufferCreate拷贝一份缓存赋值到内存变量中
                 否则会出现内存泄漏的问题
                 */
                let pixelBufferWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
                let pixelBufferHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
                let format = CVPixelBufferGetPixelFormatType((imageBuffer))
                let attrs: [String: Any] = [
                    kCVPixelBufferMetalCompatibilityKey as String: true,
                    kCVPixelBufferCGImageCompatibilityKey as String: true,
                    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:]
                ]
                var cachePixelBuffer: CVPixelBuffer?
                CVPixelBufferCreate(nil, Int(pixelBufferWidth), Int(pixelBufferHeight),
                                    format, attrs as CFDictionary, &cachePixelBuffer)
                guard let pixelBuffer = cachePixelBuffer else {
                    continue
                }
                /* ======================================================================= */
                let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                let duration = CMSampleBufferGetDuration(sampleBuffer)
                let videoFrameModel = PEDTVideoFrameModel(pixelBuffer: pixelBuffer, pts: pts, duration: duration)
                self.videoFrameModels.append(videoFrameModel)
            }
            
            if (.completed == assetReader.status ||
                .failed == assetReader.status ||
                .cancelled == assetReader.status) {
                DispatchQueue.main.async {
                    completionCallback?(self.videoFrameModels)
                }
            }
            
        }
    }
    
    /// 读取Video资源中音频数据Description格式描述
    /// - Parameter completionCallback: 完成后的Callback回调函数
    func readVideoSourceAndGetAudioDescription(completionCallback: ((_ formatDescription: CMFormatDescription?, _ audioStreamBasicDescription: AudioStreamBasicDescription?) -> Void)? = nil) {
        guard let asset = self.videoAsset else {
            completionCallback?(nil, nil)
            return
        }
        
        guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
            completionCallback?(nil, nil)
            return
        }
        
        Task {
            guard let formatDescriptions: [CMFormatDescription] = try? await audioTrack.load(.formatDescriptions) else {
                completionCallback?(nil, nil)
                return
            }
            
            guard let formatDescription = formatDescriptions.first else {
                completionCallback?(nil, nil)
                return
            }
            
            guard let audioStreamBasicDescription = formatDescription.audioStreamBasicDescription else {
                completionCallback?(formatDescription, nil)
                return
            }
            self.audioStreamBasicDescription = audioStreamBasicDescription
            print(audioStreamBasicDescription)
            
            completionCallback?(formatDescription, audioStreamBasicDescription)
        }
    }
    
    func readVideoSourceAndDecodeToAudioPcm(completionCallback: ((_ audioFrameModels: [PEDTAudioFrameModel]) -> Void)? = nil) {
        self.readVideoSourceAndGetAudioDescription { formatDescription, audioStreamBasicDescription in
            guard let asset = self.videoAsset else {
                completionCallback?(self.audioFrameModels)
                return
            }
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                completionCallback?(self.audioFrameModels)
                return
            }
            guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
                completionCallback?(self.audioFrameModels)
                return
            }
            
            var audioReaderSettings = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: kAudioSampleRate,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMIsBigEndianKey: false
            ] as [String : Any]
            if let audioStreamBasicDescription = audioStreamBasicDescription {
                audioReaderSettings = [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: audioStreamBasicDescription.mSampleRate,
                    AVNumberOfChannelsKey: audioStreamBasicDescription.mChannelsPerFrame,
                    AVLinearPCMBitDepthKey: 32,
                    AVLinearPCMIsFloatKey: true,
                    AVLinearPCMIsBigEndianKey: false,
                ] as [String : Any]
            }
            
            let audioOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: audioReaderSettings)
            guard assetReader.canAdd(audioOutput) else {
                completionCallback?(self.audioFrameModels)
                return
            }
            assetReader.add(audioOutput)
            assetReader.startReading()
            
            DispatchQueue(label: "\(Self.self)_\(#function)").async {
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
                    let sampleCount = CMSampleBufferGetNumSamples(sampleBuffer)
                    let audioFrameModel = PEDTAudioFrameModel(pcmData: pcm, pts: pts, sampleCount: sampleCount)
                    self.audioFrameModels.append(audioFrameModel)
                }
                
                if (.completed == assetReader.status) {
                    DispatchQueue.main.async {
                        /*
                         最后一帧音频采样不完整
                         写入时会造成时间序列对不齐而造成写入失败
                         暂时移除掉,后续再想其他办法进行优化
                         */
                        self.audioFrameModels.removeLast()
                        /* ========================================== */
                        completionCallback?(self.audioFrameModels)
                    }
                }
                
            }
        }
        
    }
    
    var isVideoInputFinished = false
    var isAudioInputFinished = true
    func exportVideoSource(outputURL: URL, completionCallback: ((_ outputPath: URL?) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            let videoSourcePath = outputURL.path
            if (FileManager.default.fileExists(atPath: videoSourcePath) == true) {
                do {
                    try FileManager.default.removeItem(atPath: videoSourcePath)
                } catch {
                    print("FileManager.default.removeItem操作失败")
                }
            }
            
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
                completionCallback?(nil)
                return
            }
            
            // ---- Video Input ----
            guard let firstFrameModel = self.videoFrameModels.first else {
                completionCallback?(nil)
                return
            }
            let width = CVPixelBufferGetWidth(firstFrameModel.pixelBuffer)
            let height = CVPixelBufferGetHeight(firstFrameModel.pixelBuffer)
            let pixelFormat = CVPixelBufferGetPixelFormatType(firstFrameModel.pixelBuffer)
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
            
            // ---- Audio Input ----
            var audioInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVSampleRateKey: kAudioSampleRate,
                    AVNumberOfChannelsKey: 2,
                    AVEncoderBitRateKey: 128000
                ]
            )
            if let audioStreamBasicDescription = self.audioStreamBasicDescription {
                audioInput = AVAssetWriterInput(
                    mediaType: .audio,
                    outputSettings: [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: audioStreamBasicDescription.mSampleRate,
                        AVNumberOfChannelsKey: audioStreamBasicDescription.mChannelsPerFrame,
                        AVEncoderBitRateKey: 128000
                    ]
                )
            }
            
            assetWriter.add(audioInput)
            
            assetWriter.startWriting()
            assetWriter.startSession(atSourceTime: .zero)
            
            DispatchQueue.main.async {
                var videoFrameIndex = 0
                videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "\(Self.self)_\(#function)_videoInput_requestMediaDataWhenReady()")) { [weak videoInput] in
                    guard let videoInput = videoInput else {
                        return
                    }
                    while videoInput.isReadyForMoreMediaData {
                        if (videoFrameIndex >= self.videoFrameModels.count) {
                            videoInput.markAsFinished()
                            self.isVideoInputFinished = true
                            if (self.isVideoInputFinished == true && self.isAudioInputFinished == true) {
                                assetWriter.finishWriting {
                                    if assetWriter.status == .completed {
                                        DispatchQueue.main.async {
                                            completionCallback?(outputURL)
                                        }
                                    } else if let error = assetWriter.error {
                                        DispatchQueue.main.async {
                                            completionCallback?(outputURL)
                                        }
                                        print("写入失败 ❌", error, videoSourcePath)
                                    }
                                }
                            }
                            return
                        }
                        
                        let videoFrameModel = self.videoFrameModels[videoFrameIndex]
                        let timescale: CMTimeScale = CMTimeScale(self.fps)
                        let pts = CMTime(value: Int64(videoFrameIndex),timescale: timescale)
                        
                        let isSuccess = adaptor.append(videoFrameModel.pixelBuffer, withPresentationTime: pts)
                        if (isSuccess == false) {
                            videoInput.markAsFinished()
                            self.isVideoInputFinished = true
                            if (self.isVideoInputFinished == true && self.isAudioInputFinished == true) {
                                assetWriter.finishWriting {
                                    if assetWriter.status == .completed {
                                        DispatchQueue.main.async {
                                            completionCallback?(outputURL)
                                        }
                                    } else if let error = assetWriter.error {
                                        DispatchQueue.main.async {
                                            completionCallback?(outputURL)
                                        }
                                        print("写入失败 ❌", error, videoSourcePath)
                                    }
                                }
                            }
                            return
                        }
                        videoFrameIndex = videoFrameIndex + 1
                    }
                }
            }
            
            DispatchQueue.main.async {
                var audioFrameIndex = 0
                var sampleCountSumValue = 0
                audioInput.requestMediaDataWhenReady(on: DispatchQueue(label: "\(Self.self)_\(#function)_audioInput_requestMediaDataWhenReady()")) { [weak audioInput] in
                    guard let audioInput = audioInput else {
                        return
                    }
                    while audioInput.isReadyForMoreMediaData {
                        if (audioFrameIndex >= self.audioFrameModels.count) {
                            audioInput.markAsFinished()
                            self.isAudioInputFinished = true
                            if (self.isVideoInputFinished == true && self.isAudioInputFinished == true) {
                                assetWriter.finishWriting {
                                    if assetWriter.status == .completed {
                                        DispatchQueue.main.async {
                                            completionCallback?(outputURL)
                                        }
                                    } else if let error = assetWriter.error {
                                        DispatchQueue.main.async {
                                            completionCallback?(outputURL)
                                        }
                                        print("写入失败 ❌", error, videoSourcePath)
                                    }
                                }
                            }
                            return
                        }
                        
                        let audioFrameModel = self.audioFrameModels[audioFrameIndex]
                        let pcmData = audioFrameModel.pcmData
                        let sampleCount = audioFrameModel.sampleCount
                        let pts = CMTime(value: CMTimeValue(sampleCountSumValue),timescale: CMTimeScale(kAudioSampleRate))
                        guard let sampleBuffer = PEDTVideoClipsEditHelper.makeAudioSampleBuffer(pcmData: pcmData, sampleCount: sampleCount, pts: pts, audioStreamBasicDescription: self.audioStreamBasicDescription) else {
                            audioFrameIndex = audioFrameIndex + 1
                            continue
                        }
                        
                        let isSuccess = audioInput.append(sampleBuffer)
                        if (isSuccess == false) {
                            audioInput.markAsFinished()
                            self.isAudioInputFinished = true
                            if (self.isVideoInputFinished == true && self.isAudioInputFinished == true) {
                                assetWriter.finishWriting {
                                    if assetWriter.status == .completed {
                                        DispatchQueue.main.async {
                                            completionCallback?(outputURL)
                                        }
                                    } else if let error = assetWriter.error {
                                        DispatchQueue.main.async {
                                            completionCallback?(outputURL)
                                        }
                                        print("写入失败 ❌", error, videoSourcePath)
                                    }
                                }
                            }
                            return
                        }
                        
                        audioFrameIndex = audioFrameIndex + 1
                        sampleCountSumValue = sampleCountSumValue + sampleCount
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
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
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
    
    /// 制作Audio音频SampleBuffer
    /// - Parameters:
    ///   - pcmData: PCM音频数据流
    ///   - sampleCount: 采样数量
    ///   - pts: 音频时间戳
    /// - Returns: SampleBuffer音频采样数据流
    static func makeAudioSampleBuffer(pcmData: Data, sampleCount: Int, pts: CMTime,
                                      audioStreamBasicDescription: AudioStreamBasicDescription?) -> CMSampleBuffer? {
        // 1. AudioStreamBasicDescription
        var asbd = AudioStreamBasicDescription(
            mSampleRate: kAudioSampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 4,      // 2ch × 16bit = 4
            mFramesPerPacket: 1,
            mBytesPerFrame: 4,
            mChannelsPerFrame: 2,
            mBitsPerChannel: 16,
            mReserved: 0
        )
        if let audioStreamBasicDescription = audioStreamBasicDescription {
            asbd = AudioStreamBasicDescription(
                mSampleRate: audioStreamBasicDescription.mSampleRate,
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
                mBytesPerPacket: 4,      // 2ch × 16bit = 4
                mFramesPerPacket: 1,
                mBytesPerFrame: 4,
                mChannelsPerFrame: audioStreamBasicDescription.mChannelsPerFrame,
                mBitsPerChannel: 16,
                mReserved: 0
            )
        }
        
        var formatDesc: CMAudioFormatDescription?
        CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &asbd,
            layoutSize: 0, layout: nil,
            magicCookieSize: 0, magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDesc
        )
        guard formatDesc != nil else {
            return nil
        }
        
        // 2. CMBlockBuffer（把 Data 塞进去）
        var blockBuffer: CMBlockBuffer?
        CMBlockBufferCreateWithMemoryBlock(
            allocator: kCFAllocatorDefault,
            memoryBlock: nil,
            blockLength: pcmData.count,
            blockAllocator: nil,
            customBlockSource: nil,
            offsetToData: 0,
            dataLength: pcmData.count,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        let resultType = pcmData.withUnsafeBytes { raw in
            CMBlockBufferReplaceDataBytes(
                with: raw.baseAddress!,
                blockBuffer: blockBuffer!,
                offsetIntoDestination: 0,
                dataLength: pcmData.count
            )
        }
        print("resultType = \(resultType)")
        
        
        // 3. CMSampleBuffer
        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: Int32(kAudioSampleRate)), // 每段 duration
            presentationTimeStamp: pts,   // ★ 用缓存时记的 PTS
            decodeTimeStamp: .invalid
        )
        
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: blockBuffer,
            dataReady: true,
            makeDataReadyCallback: nil, refcon: nil,
            formatDescription: formatDesc,
            sampleCount: sampleCount,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timing,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        return sampleBuffer
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
        let format = CVPixelBufferGetPixelFormatType((inputPixelBuffer))
        let status = CVPixelBufferCreate(
            nil,
            width, height,
            format,   // 或保持原格式
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
        let format = CVPixelBufferGetPixelFormatType((inputPixelBuffer))
        let status = CVPixelBufferCreate(
            nil,
            Int(inputCoreImage.extent.width), Int(inputCoreImage.extent.height),
            format,   // 或保持原格式
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
    /// 视频时间戳
    let pts: CMTime
    
    /// 总时长
    let duration: CMTime
}

/// 音频帧eModel数据模型
struct PEDTAudioFrameModel {
    /// 音频流数据
    var pcmData: Data
    /// 音频时间戳(音频时间戳和视频时间戳是不一样的,需要单独获取并赋值)
    let pts: CMTime
    
    /// 采样数量
    var sampleCount: Int
    
}
