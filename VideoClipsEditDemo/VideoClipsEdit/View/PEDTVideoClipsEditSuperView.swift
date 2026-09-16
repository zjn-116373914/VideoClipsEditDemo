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
    public func loadVideoSource(videoURL: URL, decompressionCompletionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]) -> Void)? = nil) {
        let asset = AVAsset(url: videoURL)
        self.videoClipsEditManager.loadVideoSource(asset: asset)
        self.videoClipsEditManager.readVideoSourceAndDecompression { [weak self] videoFrameModels in
            guard let self = self else {
                return
            }
            decompressionCompletionCallback?(videoFrameModels)
            
            guard let firstFrameModel = videoFrameModels.first else {
                return
            }
            self.videoPlayImageView.image = PEDTVideoClipsEditHelper.imageWithPixelBuffer(pixelBuffer: firstFrameModel.pixelBuffer)
            
            var images = [UIImage]()
            let maxCount = PEDTVideoClipsContentView.imageItemMaxCount
            let step = Int(videoFrameModels.count/maxCount)
            for index in stride(from: 0, through: videoFrameModels.count - 1, by: step) {
                let videoFrameModel = videoFrameModels[index]
                let smallPixelBuffer = PEDTVideoClipsEditHelper.resizePixelBuffer(videoFrameModel.pixelBuffer, width: 100, height: 100)
                guard let smallPixelBuffer = smallPixelBuffer else {
                    continue
                }
                guard let image = PEDTVideoClipsEditHelper.imageWithPixelBuffer(pixelBuffer: smallPixelBuffer) else {
                    continue
                }
                images.append(image)
            }
            self.videoClipsEditBottomView.videoClipsContentView.images.removeAll()
            self.videoClipsEditBottomView.videoClipsContentView.images.append(contentsOf: images)
        }

    }
    
    /// 视频资源导出
    /// - Parameters:
    ///   - outputURL: 导出路径
    ///   - exportCompletionCallback: 导出完成后的Callback回调函数
    public func exportVideoSource(outputURL: URL, exportCompletionCallback: ((_ outputPath: URL?) -> Void)? = nil) {
        self.videoClipsEditManager.exportVideoSource(outputURL: outputURL, exportCompletionCallback: exportCompletionCallback)
        self.videoClipsEditBottomView.videoClipsDragView.setEndRatio(value: 0.5)
    }
    
    /// 视频片段剪切
    public func cropVideoClips(completionCallback: ((_ videoFrameModels: [PEDTVideoFrameModel]?) -> Void)? = nil) {
        DispatchQueue(label: "\(Self.self)_\(#function)").async {
            let startRatio = self.videoClipsEditBottomView.videoClipsDragView.startRatio
            let endRatio = self.videoClipsEditBottomView.videoClipsDragView.endRatio
            let videoFrameModels = self.videoClipsEditManager.videoFrameModels
            
            let startIndex = Int(startRatio * CGFloat(videoFrameModels.count - 1))
            let endIndex = Int(endRatio * CGFloat(videoFrameModels.count - 1))
            if (endIndex - startIndex) <= 0 {
                return
            }
            
            let cacheVideoFrameModels = videoFrameModels[startIndex...endIndex]
            self.videoClipsEditManager.videoFrameModels.removeAll()
            self.videoClipsEditManager.videoFrameModels.append(contentsOf: cacheVideoFrameModels)
            
            DispatchQueue.main.async {
                self.videoClipsEditBottomView.videoClipsDragView.setEndRatio(value: 1.0)
                self.videoClipsEditBottomView.videoClipsDragView.setStartRatio(value: 0.0)
                completionCallback?(self.videoClipsEditManager.videoFrameModels)
            }
        }
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
