//
//  PEDTVideoClipsEditView.swift
//  VideoEditDemo
//
//  Created by zjn-apple on 2026/9/12.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit

/// 视频进度编辑器的主体视图
class PEDTVideoClipsEditBottomView: UIView {
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
        self.videoClipsContentView.backgroundColor = UIColor.black
        self.videoClipsContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.videoClipsContentView.topAnchor.constraint(equalTo: self.topAnchor, constant: 15),
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
        let myself = UIView()
        return myself
    }()
    
    /// 视频进度拖拽控件
    lazy var videoClipsDragView = {
        let myself = PEDTVideoClipsDragView()
        return myself
    }()
}

class PEDTVideoClipsDragView: UIView {
    static let dragItemWidth = 15.0
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init() {
        super.init(frame: CGRectZero)
        

    }
    var isFinishedLayout = false
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if (self.isFinishedLayout == true || self.frame.size.equalTo(CGSizeZero)) {
            return
        }
        self.isFinishedLayout = true
        
        let dragItemWidth = PEDTVideoClipsDragView.dragItemWidth
        let dragItemHeight = self.frame.size.height
        let superViewWidth = self.frame.size.width
        
        self.addSubview(self.leftDragItem)
        self.leftDragItem.frame = CGRectMake(0, 0, dragItemWidth, dragItemHeight)
        
        self.addSubview(self.rightDragItem)
        self.rightDragItem.frame = CGRectMake(superViewWidth - dragItemWidth, 0,
                                              dragItemWidth, dragItemHeight)
    }
    
    
    // MARK: - ================= Get And Set =================
    /// 开始比例
    @objc dynamic var startRatio = 0.0
    func setStartRatio(value: CGFloat) {
        self.startRatio = value
        let leftDragItemX = startRatio * (CGRectGetWidth(self.frame) -
                                          CGRectGetWidth(self.leftDragItem.frame) - CGRectGetWidth(self.rightDragItem.frame)) - CGRectGetWidth(self.leftDragItem.frame) + CGRectGetWidth(self.rightDragItem.frame)
        self.leftDragItem.frame = CGRectMake(leftDragItemX,
                                             self.leftDragItem.frame.origin.y,
                                             self.leftDragItem.frame.size.width,
                                             self.leftDragItem.frame.size.height)
        self.setNeedsDisplay()
    }
    
    /// 左侧 进度条滑块
    lazy var leftDragItem = {
        let myself = UIView()
        myself.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(leftDragItemPanGestureRecognizerAction)))
        return myself
    }()
    @objc func leftDragItemPanGestureRecognizerAction(panGesture: UIPanGestureRecognizer) {
        guard let targetView = panGesture.view else {
            return
        }
        guard let superview = targetView.superview else {
            return
        }
        let pp = panGesture.translation(in: superview)
        var targetCenterPoint = CGPointMake(targetView.centerX + pp.x, targetView.centerY)
        
        let rightDragItemMinX = CGRectGetMinX(self.rightDragItem.frame)
        let targetViewWidth = targetView.frame.size.width
        targetCenterPoint.x = max(targetViewWidth/2, targetCenterPoint.x)
        targetCenterPoint.x = min(rightDragItemMinX - targetViewWidth/2, targetCenterPoint.x)
        
        targetView.center = targetCenterPoint
        panGesture.setTranslation(CGPointZero, in: superview)
        
        self.setNeedsDisplay()
        /* ====================== 计算视频进度条开始位置和结束位置的比例 start ====================== */
        let startPointX = 0.0 + CGRectGetWidth(self.leftDragItem.frame)
        let endPointX = CGRectGetWidth(self.frame) - CGRectGetWidth(self.rightDragItem.frame)
        let targetPointX = CGRectGetMaxX(self.leftDragItem.frame)
        self.startRatio = (targetPointX - startPointX)/(endPointX - startPointX)
        /* ====================== 计算视频进度条开始位置和结束位置的比例 end ====================== */
    }
    
    /// 结束比例
    @objc dynamic var endRatio = 1.0
    func setEndRatio(value: CGFloat) {
        self.endRatio = value
        let rightDragItemX = endRatio * (CGRectGetWidth(self.frame) -
                                         CGRectGetWidth(self.leftDragItem.frame) - CGRectGetWidth(self.rightDragItem.frame)) + CGRectGetWidth(self.leftDragItem.frame)
        self.rightDragItem.frame = CGRectMake(rightDragItemX,
                                             self.rightDragItem.frame.origin.y,
                                             self.rightDragItem.frame.size.width,
                                             self.rightDragItem.frame.size.height)
        self.setNeedsDisplay()
    }
    /// 右侧 进度条滑块
    lazy var rightDragItem = {
        let myself = UIView()
        myself.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(rightDragItemPanGestureRecognizerAction)))
        return myself
    }()
    @objc func rightDragItemPanGestureRecognizerAction(panGesture: UIPanGestureRecognizer) {
        guard let targetView = panGesture.view else {
            return
        }
        guard let superview = targetView.superview else {
            return
        }
        let pp = panGesture.translation(in: superview)
        var targetCenterPoint = CGPointMake(targetView.centerX + pp.x, targetView.centerY)
        
        let leftDragItemMaxX = CGRectGetMaxX(self.leftDragItem.frame)
        let targetViewWidth = targetView.frame.size.width
        let superviewWidth = superview.frame.size.width
        targetCenterPoint.x = max(leftDragItemMaxX + targetViewWidth/2, targetCenterPoint.x)
        targetCenterPoint.x = min(superviewWidth - targetViewWidth/2, targetCenterPoint.x)
        
        targetView.center = targetCenterPoint
        panGesture.setTranslation(CGPointZero, in: superview)
        
        self.setNeedsDisplay()
        /* ====================== 计算视频进度条开始位置和结束位置的比例 start ====================== */
        let startPointX = 0.0 + CGRectGetWidth(self.leftDragItem.frame)
        let endPointX = CGRectGetWidth(self.frame) - CGRectGetWidth(self.rightDragItem.frame)
        let targetPointX = CGRectGetMinX(self.rightDragItem.frame)
        self.endRatio = (targetPointX - startPointX)/(endPointX - startPointX)
        /* ====================== 计算视频进度条开始位置和结束位置的比例 end ====================== */
    }

    

    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        let dragItemWidth = PEDTVideoClipsDragView.dragItemWidth
        let dragItemHeight = rect.height
        let dragLineWidth = 2.0
        let dragLineHeight = rect.height * 0.3
        let fillCGColor = CGColor(red: 247.0/255.0, green: 206.0/255.0, blue: 70.0/255.0, alpha: 1.0)
        let fillColor = UIColor(red: 247.0/255.0, green: 206.0/255.0, blue: 70.0/255.0, alpha: 1.0)
        let cornerRadius = 10
        
        let leftDragItemMinX = CGRectGetMinX(self.leftDragItem.frame)
        let rightDragItemMinX = CGRectGetMinX(self.rightDragItem.frame)
        /* ===================== 左侧拖拽控件 start ===================== */
        let leftDragItemPath = UIBezierPath(roundedRect: self.leftDragItem.frame,
                                            byRoundingCorners: [.topLeft, .bottomLeft],
                                            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        context.setBlendMode(.normal)
        fillColor.setFill()
        leftDragItemPath.fill()
        
        //创建路径
        let leftDragLinePath = CGMutablePath()
        leftDragLinePath.addRoundedRect(in: CGRectMake(leftDragItemMinX + dragItemWidth/2.0 - dragLineWidth/2.0,
                                                       dragItemHeight/2.0 - dragLineHeight/2.0,
                                                        dragLineWidth, dragLineHeight),
                                         cornerWidth: 1, cornerHeight: 1)
        //添加绘制轨迹路径
        context.addPath(leftDragLinePath)
        //开始在绘图层绘制图像
        context.setBlendMode(.clear)
        context.fillPath()
        /* ===================== 左侧拖拽控件 end ===================== */
        
        
        /* ===================== 右侧拖拽控件 start ===================== */
        let rightDragItemPath = UIBezierPath(roundedRect: self.rightDragItem.frame,
                                            byRoundingCorners: [.topRight, .bottomRight],
                                            cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        context.setBlendMode(.normal)
        fillColor.setFill()
        rightDragItemPath.fill()
        
        //创建路径
        let rightDragLinePath = CGMutablePath()
        rightDragLinePath.addRoundedRect(in: CGRectMake(rightDragItemMinX + dragItemWidth/2.0 - dragLineWidth/2.0,
                                                        dragItemHeight/2.0 - dragLineHeight/2.0,
                                                        dragLineWidth, dragLineHeight),
                                         cornerWidth: 1, cornerHeight: 1)
        //添加绘制轨迹路径
        context.addPath(rightDragLinePath)
        //开始在绘图层绘制图像
        context.setBlendMode(.clear)
        context.fillPath()
        /* ===================== 右侧拖拽控件 end ===================== */
        
        let boundaryMinX = CGRectGetMaxX(self.leftDragItem.frame)
        let boundaryMaxX = CGRectGetMinX(self.rightDragItem.frame)
        let topBottomBoundaryHeight = 5.0
        /* ===================== 顶部边界控件 start ===================== */
        //创建路径
        let topBoundaryPath = CGMutablePath()
        //移动到指定位置(设置路径起点)
        topBoundaryPath.move(to: CGPointMake(boundaryMinX, 0))
        //添加绘制轨迹
        topBoundaryPath.addLine(to: CGPointMake(boundaryMaxX, 0))
        //添加绘制轨迹
        topBoundaryPath.addLine(to: CGPointMake(boundaryMaxX, topBottomBoundaryHeight))
        //添加绘制轨迹
        topBoundaryPath.addLine(to: CGPointMake(boundaryMinX, topBottomBoundaryHeight))
        
        //添加绘制轨迹路径
        context.addPath(topBoundaryPath)
        context.setFillColor(fillCGColor)
        //开始在绘图层绘制图像
        context.setBlendMode(.normal)
        context.fillPath()
        /* ===================== 顶部边界控件 end ===================== */
        
        /* ===================== 底部边界控件 start ===================== */
        //创建路径
        let bottomBoundaryPath = CGMutablePath()
        //移动到指定位置(设置路径起点)
        bottomBoundaryPath.move(to: CGPointMake(boundaryMinX, rect.height - topBottomBoundaryHeight))
        //添加绘制轨迹
        bottomBoundaryPath.addLine(to: CGPointMake(boundaryMaxX, rect.height - topBottomBoundaryHeight))
        //添加绘制轨迹
        bottomBoundaryPath.addLine(to: CGPointMake(boundaryMaxX, rect.height))
        //添加绘制轨迹
        bottomBoundaryPath.addLine(to: CGPointMake(boundaryMinX, rect.height))
        
        //添加绘制轨迹路径
        context.addPath(bottomBoundaryPath)
        context.setFillColor(fillCGColor)
        //开始在绘图层绘制图像
        context.setBlendMode(.normal)
        context.fillPath()
        /* ===================== 底部边界控件 end ===================== */
        

    }
    

}
