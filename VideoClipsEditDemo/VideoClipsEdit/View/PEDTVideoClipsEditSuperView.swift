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
        self.videoPlayImageView.backgroundColor = UIColor.red
        
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
        }
    }
    
    public func exportVideoSource(outputURL: URL, exportCompletionCallback: ((_ outputPath: URL?) -> Void)? = nil) {
        self.videoClipsEditManager.exportVideoSource(outputURL: outputURL, exportCompletionCallback: exportCompletionCallback)
        
//        self.videoClipsEditBottomView.videoClipsDragView.setStartRatio(value: 0.5)
        self.videoClipsEditBottomView.videoClipsDragView.setEndRatio(value: 0.5)
    }
    
    public func cropVideoClips() {
        
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
        let myself = PEDTVideoClipsEditBottomView()
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
