//
//  PEDTVideoClipsContentView.swift
//  VideoClipsEditDemo
//
//  Created by zjn-apple on 2026/9/16.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit

class PEDTVideoClipsContentView: UIView {
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init() {
        super.init(frame: CGRectZero)
        self.backgroundColor = UIColor.black
    }
    // MARK: - ================= Get And Set =================
    static let imageItemMaxCount = 20
    /// 视频片段预览图集合
    var images = [UIImage]() {
        didSet {
            for subImageItem in self.subImageItems {
                subImageItem.removeFromSuperview()
            }
            self.subImageItems.removeAll()
            
            let maxCount = PEDTVideoClipsContentView.imageItemMaxCount
            let itemWidth = CGRectGetWidth(self.frame)/CGFloat(maxCount)
            for index in images.indices {
                let image = images[index]
                let imageItem = UIImageView(image: image)
                self.addSubview(imageItem)
                imageItem.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    imageItem.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0),
                    imageItem.widthAnchor.constraint(equalToConstant: itemWidth),
                    imageItem.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.9),
                    imageItem.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: CGFloat(index) * itemWidth),
                ])
                self.subImageItems.append(imageItem)
            }
        }
    }
    ///
    var subImageItems = [UIImageView]()

    
}
