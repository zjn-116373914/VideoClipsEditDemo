//
//  PEDTVideoProgressEditBodyView.swift
//  VideoProgressEditDemo
//
//  Created by zjn-apple on 2026/9/13.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit
import AVFoundation

class PEDTVideoProgressEditBodyView: UIView {
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
        
        self.addSubview(self.videoProgressEditBottomView)
        self.videoProgressEditBottomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.videoProgressEditBottomView.topAnchor.constraint(equalTo: self.videoPlayImageView.bottomAnchor, constant: 10),
            self.videoProgressEditBottomView.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
            self.videoProgressEditBottomView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1.0, constant: -20),
            self.videoProgressEditBottomView.heightAnchor.constraint(equalToConstant: 80.0)
        ])
    }
    
    /// 加载视频资源
    /// - Parameter videoURL: 资源URL链接
    public func loadVideoSource(videoURL: URL) {
        let asset = AVAsset(url: videoURL)
        self.videoProgressEditManager.loadVideoSource(asset: asset)
        
        self.videoProgressEditManager.decompressionSampleBufferToPixelBufferCompletionBlock = { outputPixelBuffer in
            kLog("outputPixelBuffer = \(outputPixelBuffer)")
        }
        self.videoProgressEditManager.readVideoSource()
    }
    public func readVideoSource() {
        self.videoProgressEditManager.readVideoSource()
    }
    
    // MARK: - ================= Get And Set =================
    ///
    lazy var videoProgressEditManager = {
        let myself = PEDTVideoProgressEditManager()
        return myself
    }()
    ///
    lazy var videoPlayImageView = {
        let myself = UIImageView()
        myself.contentMode = .scaleAspectFit
        return myself
    }()
    
    ///
    lazy var videoProgressEditBottomView = {
        let myself = PEDTVideoProgressEditBottomView()
        return myself
    }()
}
