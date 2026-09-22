//
//  PEDTVideoClipsEditView.swift
//  VideoEditDemo
//
//  Created by zjn-apple on 2026/9/12.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit

/// 视频进度编辑器的主体视图
class PEDTVideoClipsBottomSuperView: UIView {
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init() {
        super.init(frame: CGRectZero)
        self.backgroundColor = UIColor.darkGray
        self.layer.cornerRadius = 10
        self.clipsToBounds = true
        
        self.addSubview(self.backgroundVisualEffectView)
        self.backgroundVisualEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.backgroundVisualEffectView.topAnchor.constraint(equalTo: self.topAnchor, constant: 0),
            self.backgroundVisualEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 0),
            self.backgroundVisualEffectView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            self.backgroundVisualEffectView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0)
        ])
        
        self.addSubview(self.playAndPauseBtn)
        self.playAndPauseBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.playAndPauseBtn.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
            self.playAndPauseBtn.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 10),
            self.playAndPauseBtn.widthAnchor.constraint(equalToConstant: 40),
            self.playAndPauseBtn.heightAnchor.constraint(equalToConstant: 40),
        ])
        
        self.addSubview(self.videoClipsContentView)
        self.videoClipsContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.videoClipsContentView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0.0),
            self.videoClipsContentView.heightAnchor.constraint(equalTo: self.heightAnchor, constant: -30),
            self.videoClipsContentView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -15),
            self.videoClipsContentView.leadingAnchor.constraint(equalTo: self.playAndPauseBtn.trailingAnchor, constant: 15),
            self.videoClipsContentView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
        ])
        
        self.addSubview(self.videoClipsDragView)
        self.videoClipsDragView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.videoClipsDragView.topAnchor.constraint(equalTo: self.videoClipsContentView.topAnchor, constant: -5),
            self.videoClipsDragView.bottomAnchor.constraint(equalTo: self.videoClipsContentView.bottomAnchor, constant: 5),
            self.videoClipsDragView.leadingAnchor.constraint(equalTo: self.videoClipsContentView.leadingAnchor, constant: -5),
            self.videoClipsDragView.trailingAnchor.constraint(equalTo: self.videoClipsContentView.trailingAnchor, constant: 5),
        ])
        self.videoClipsDragView.backgroundColor = UIColor.clear
    }
    

    // MARK: - ================= Get And Set =================
    /// 背景视图
    lazy var backgroundVisualEffectView = {
        let myself = UIView()
        
        let effect = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let visualEffectView = UIVisualEffectView(effect: effect)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        myself.addSubview(visualEffectView)
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: myself.topAnchor, constant: 0),
            visualEffectView.bottomAnchor.constraint(equalTo: myself.bottomAnchor, constant: 0),
            visualEffectView.leftAnchor.constraint(equalTo: myself.leftAnchor, constant: 0),
            visualEffectView.rightAnchor.constraint(equalTo: myself.rightAnchor, constant: 0)
        ])
        
        return myself
    }()
    
    /// [播放/暂停]按钮控件
    lazy var  playAndPauseBtn = {
        let myself = UIButton(type: .system)
        myself.tintColor = UIColor.clear
        if let icon = UIImage(named: "PEDT_VideoClipsEditBody_PlayBtn_Normal") {
            myself.setImage(icon.withRenderingMode(.alwaysOriginal), for: .normal)
        }
        if let icon = UIImage(named: "PEDT_VideoClipsEditBody_PlayBtn_Selected") {
            myself.setImage(icon.withRenderingMode(.alwaysOriginal), for: .selected)
        }
       
        return myself
    }()
    
    /// 视频进行内容视图
    lazy var videoClipsContentView = {
        let myself = PEDTVideoClipsContentView()
        return myself
    }()
    
    /// 视频进度拖拽控件
    lazy var videoClipsDragView = {
        let myself = PEDTVideoClipsDragView()
        return myself
    }()
}
