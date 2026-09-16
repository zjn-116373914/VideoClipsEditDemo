//
//  PEDTVideoClipsDragView.swift
//  VideoClipsEditDemo
//
//  Created by zjn-apple on 2026/9/16.
//  Copyright © 2026 Artanis Protoss. All rights reserved.
//

import UIKit

class PEDTVideoClipsDragView: UIView {
    static let dragItemWidth = 15.0
    
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
