//
//  PEDTVideoClipsEditSuperView.swift
//  VideoClipsEditDemo
//
//  Created by zjn-apple on 2026/9/13.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit
import AVFoundation

class PEDTVideoClipsEditSuperView: UIView {
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init() {
        super.init(frame: CGRectZero)
        self.addSubview(self.videoPlayImageView)
        self.videoPlayImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.videoPlayImageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            self.videoPlayImageView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
            self.videoPlayImageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0, constant: -20),
            self.videoPlayImageView.heightAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0),
        ])
        self.videoPlayImageView.backgroundColor = UIColor.black
        self.videoPlayImageView.layer.cornerRadius = 10
        self.videoPlayImageView.clipsToBounds = true
        
        self.addSubview(self.videoClipsEditBottomView)
        self.videoClipsEditBottomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.videoClipsEditBottomView.topAnchor.constraint(equalTo: self.videoPlayImageView.bottomAnchor, constant: 10),
            self.videoClipsEditBottomView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
            self.videoClipsEditBottomView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0, constant: -20),
            self.videoClipsEditBottomView.heightAnchor.constraint(equalToConstant: 80.0)
        ])
        
        self.videoClipsStartRatioObservation = self.videoClipsEditBottomView.videoClipsDragView.observe(\.startRatio, options: [.new, .old], changeHandler: { [weak self] sender, change in
            guard let self = self else {
                return
            }
            guard let startRatio = change.newValue else {
                return
            }
            let tagetIndex = Int(CGFloat(self.videoClipsEditManager.videoFrameModels.count - 1) * startRatio)
            let targetFrameModel = self.videoClipsEditManager.videoFrameModels[tagetIndex]
            self.videoPlayImageView.image = PEDTVideoClipsEditHelper.imageWithPixelBuffer(pixelBuffer: targetFrameModel.pixelBuffer)
        })
        
        self.videoClipsEndRatioObservation = self.videoClipsEditBottomView.videoClipsDragView.observe(\.endRatio, options: [.new, .old], changeHandler: { [weak self] sender, change in
            guard let self = self else {
                return
            }
            guard let endRatio = change.newValue else {
                return
            }
            let tagetIndex = Int(CGFloat(self.videoClipsEditManager.videoFrameModels.count - 1) * endRatio)
            let targetFrameModel = self.videoClipsEditManager.videoFrameModels[tagetIndex]
            self.videoPlayImageView.image = PEDTVideoClipsEditHelper.imageWithPixelBuffer(pixelBuffer: targetFrameModel.pixelBuffer)
        })
    }
    
    /// 加载视频资源
    /// - Parameter videoURL: 资源URL链接
    public func loadVideoSource(videoURL: URL, completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel], _ audioFrameModels: [PEDTAudioFrameModel]) -> Void)? = nil) {
        let asset = AVAsset(url: videoURL)
        self.videoClipsEditManager.loadVideoSource(asset: asset)
        self.videoClipsEditManager.readVideoSourceDecodeToPixelAndPcm { [weak self] videoFrameModels, audioFrameModels in
            guard let self = self else {
                return
            }
            completionCallback?(videoFrameModels, audioFrameModels)
            
            if (videoFrameModels.count <= 0) {
                return
            }
            //更新 底部视频片段的预览图集合
            self.reloadVideoClipsPreImages()
            self.videoClipsEditBottomView.videoClipsDragView.endRatio = 1.0
            self.videoClipsEditBottomView.videoClipsDragView.startRatio = 0.0
        }

    }
    
    /// 视频资源导出
    /// - Parameters:
    ///   - outputURL: 导出路径
    ///   - exportCompletionCallback: 导出完成后的Callback回调函数
    public func exportVideoSource(outputURL: URL, exportCompletionCallback: ((_ outputPath: URL?) -> Void)? = nil) {
        self.videoClipsEditManager.exportVideoSource(outputURL: outputURL, completionCallback: exportCompletionCallback)
    }
    
    /// 视频片段剪切
    public func cropVideoClips(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel], _ audioFrameModels: [PEDTAudioFrameModel]) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            let startRatio = self.videoClipsEditBottomView.videoClipsDragView.startRatio
            let endRatio = self.videoClipsEditBottomView.videoClipsDragView.endRatio
            let videoFrameModels = self.videoClipsEditManager.videoFrameModels
            let audioFrameModels = self.videoClipsEditManager.audioFrameModels
            
            let startIndexOfVideo = Int(startRatio * CGFloat(videoFrameModels.count - 1))
            let endIndexVideo = Int(endRatio * CGFloat(videoFrameModels.count - 1))
            if (endIndexVideo - startIndexOfVideo) < 0 {
                return
            }
            let cacheVideoFrameModels = videoFrameModels[startIndexOfVideo...endIndexVideo]
            self.videoClipsEditManager.videoFrameModels.removeAll()
            self.videoClipsEditManager.videoFrameModels.append(contentsOf: cacheVideoFrameModels)
            
            let startIndexOfAudio = Int(startRatio * CGFloat(audioFrameModels.count - 1))
            let endIndexAudio = Int(endRatio * CGFloat(audioFrameModels.count - 1))
            if (endIndexAudio - startIndexOfAudio) < 0 {
                return
            }
            let cacheAudioFrameModels = audioFrameModels[startIndexOfAudio...endIndexAudio]
            self.videoClipsEditManager.audioFrameModels.removeAll()
            self.videoClipsEditManager.audioFrameModels.append(contentsOf: cacheAudioFrameModels)
            
            DispatchQueue.main.async {
                self.reloadVideoClipsPreImages()
                self.videoClipsEditBottomView.videoClipsDragView.setEndRatio(value: 1.0)
                self.videoClipsEditBottomView.videoClipsDragView.setStartRatio(value: 0.0)
                completionCallback?(self.videoClipsEditManager.videoFrameModels, self.videoClipsEditManager.audioFrameModels)
            }
        }
    }
    
    func greyRenderVideoClips(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]?) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            let startRatio = self.videoClipsEditBottomView.videoClipsDragView.startRatio
            let endRatio = self.videoClipsEditBottomView.videoClipsDragView.endRatio
            var videoFrameModels = self.videoClipsEditManager.videoFrameModels
            
            let startIndex = Int(startRatio * CGFloat(videoFrameModels.count - 1))
            let endIndex = Int(endRatio * CGFloat(videoFrameModels.count - 1))
            if (endIndex - startIndex) <= 0 {
                return
            }
            
            for index in startIndex...endIndex {
                var videoFrameModel = videoFrameModels[index]
                guard let pixelBuffer = PEDTVideoClipsEditHelper.greyRenderPixelBuffer(inputPixelBuffer: videoFrameModel.pixelBuffer) else {
                    continue
                }
                videoFrameModel.pixelBuffer = pixelBuffer
                videoFrameModels.replaceSubrange(index...index, with: [videoFrameModel])
            }
            self.videoClipsEditManager.videoFrameModels.removeAll()
            self.videoClipsEditManager.videoFrameModels.append(contentsOf: videoFrameModels)
            
            DispatchQueue.main.async {
                self.reloadVideoClipsPreImages()
                let endRatio = self.videoClipsEditBottomView.videoClipsDragView.endRatio
                self.videoClipsEditBottomView.videoClipsDragView.setEndRatio(value: endRatio)
                let startRatio = self.videoClipsEditBottomView.videoClipsDragView.startRatio
                self.videoClipsEditBottomView.videoClipsDragView.setStartRatio(value: startRatio)
                
                completionCallback?(self.videoClipsEditManager.videoFrameModels)
            }
        }
    }
    
    /// 更新 底部视频片段的预览图集合(数组更新不建议用KVO, 因为每次Add都会调用刷新界面的事件,增加CPU负担,也影响用户体验)
    func reloadVideoClipsPreImages() {
        var images = [UIImage]()
        
        let videoFrameModels = self.videoClipsEditManager.videoFrameModels
        let maxCount = PEDTVideoClipsContentView.imageItemMaxCount
        let step = Int(videoFrameModels.count/maxCount)
        for index in stride(from: 0, through: videoFrameModels.count - 1, by: step) {
            let videoFrameModel = videoFrameModels[index]
            guard let smallImage = PEDTVideoClipsEditHelper.resizePixelBufferToImage(inputPixelBuffer: videoFrameModel.pixelBuffer, width: 100, height: 100) else {
                continue
            }
            images.append(smallImage)
        }
        self.videoClipsEditBottomView.videoClipsContentView.images.removeAll()
        self.videoClipsEditBottomView.videoClipsContentView.images.append(contentsOf: images)
    }
    
    // MARK: - ================= Get And Set =================
    /// self.videoClipsEditBottomView.videoClipsDragView.startRatio的监听对象
    var videoClipsStartRatioObservation: NSKeyValueObservation?
    /// self.videoClipsEditBottomView.videoClipsDragView.endRatio的监听对象
    var videoClipsEndRatioObservation: NSKeyValueObservation?
    
    ///
    lazy var videoClipsEditManager = {
        let myself = PEDTVideoClipsEditManager()
        return myself
    }()
    ///
    lazy var videoPlayImageView = {
        let myself = UIImageView()
        myself.contentMode = .scaleAspectFit
        return myself
    }()
    
    ///
    lazy var videoClipsEditBottomView = {
        let myself = PEDTVideoClipsBottomSuperView()
        return myself
    }()
    
    
    deinit {
        //销毁监听对象
        if let videoClipsStartRatioObservation = self.videoClipsStartRatioObservation {
            videoClipsStartRatioObservation.invalidate()
        }
        //销毁监听对象
        if let videoClipsEndRatioObservation = self.videoClipsEndRatioObservation {
            videoClipsEndRatioObservation.invalidate()
        }
    }
}
