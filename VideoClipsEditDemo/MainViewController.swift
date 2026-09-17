//
//  MainViewController.swift
//  SimpleProgramSwift
//
//  Created by Artanis Protoss on 2018/10/28.
//

import UIKit
import Toast_Swift

let VideoName = "VideoSource01.MP4"
class MainViewController: UIViewController {
    lazy var videoClipsEditSuperView = {
        let myself = PEDTVideoClipsEditSuperView()
        return myself
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customNavigationBar()
        
        let exportNavBtnItem = UIBarButtonItem.init(title: NSLocalizedString("导出", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(exportNavBtnItemAction))
        let cutoutNavBtnItem = UIBarButtonItem.init(title: NSLocalizedString("剪切", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(cutoutNavBtnItemAction))
        let renderNavBtnItem = UIBarButtonItem.init(title: NSLocalizedString("渲染", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(renderNavBtnItemAction))
        self.navigationItem.rightBarButtonItems = [exportNavBtnItem, cutoutNavBtnItem, renderNavBtnItem]
        
        self.view.addSubview(self.videoClipsEditSuperView)
        self.videoClipsEditSuperView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.videoClipsEditSuperView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            self.videoClipsEditSuperView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0),
            self.videoClipsEditSuperView.widthAnchor.constraint(equalToConstant: kScreenWidth),
            self.videoClipsEditSuperView.heightAnchor.constraint(equalToConstant: kScreenWidth + 10 + 80)
        ])
        
        /* ========== [显示]过渡动画,[关闭]用户交互 start ==========  */
        kMainWindow?.isUserInteractionEnabled = false
        self.view.makeToastActivity(.center)
        /* ========== [显示]过渡动画,[关闭]用户交互 end ==========  */
        guard let videoAssetStr = Bundle.main.path(forResource: VideoName, ofType: "") else {
            return
        }
        let videoURL = NSURL(fileURLWithPath: videoAssetStr) as URL
        self.videoClipsEditSuperView.loadVideoSource(videoURL: videoURL) { [weak self] videoFrameModels in
            guard let self = self else {
                return
            }
            /* ========== [隐藏]过渡动画,[开启]用户交互 start ==========  */
            kMainWindow?.isUserInteractionEnabled = true
            self.view.hideToastActivity()
            /* ========== [隐藏]过渡动画,[开启]用户交互 end ==========  */
            
        }
    }
    
    @objc func renderNavBtnItemAction(sender: UIBarButtonItem) {
        /* ========== [显示]过渡动画,[关闭]用户交互 start ==========  */
        kMainWindow?.isUserInteractionEnabled = false
        self.view.makeToastActivity(.center)
        /* ========== [显示]过渡动画,[关闭]用户交互 end ==========  */
        self.videoClipsEditSuperView.greyRenderVideoClips { videoFrameModels in
            /* ========== [隐藏]过渡动画,[开启]用户交互 start ==========  */
            kMainWindow?.isUserInteractionEnabled = true
            self.view.hideToastActivity()
            /* ========== [隐藏]过渡动画,[开启]用户交互 end ==========  */
        }
        
    }
    
    /// 导航栏[裁剪]BarItem的响应事件
    /// - Parameter sender: BarItem对象
    @objc func cutoutNavBtnItemAction (sender: UIBarButtonItem) {
        /* ========== [显示]过渡动画,[关闭]用户交互 start ==========  */
        kMainWindow?.isUserInteractionEnabled = false
        self.view.makeToastActivity(.center)
        /* ========== [显示]过渡动画,[关闭]用户交互 end ==========  */
        self.videoClipsEditSuperView.cropVideoClips { videoFrameModels in
            /* ========== [隐藏]过渡动画,[开启]用户交互 start ==========  */
            kMainWindow?.isUserInteractionEnabled = true
            self.view.hideToastActivity()
            /* ========== [隐藏]过渡动画,[开启]用户交互 end ==========  */
        }
    }
    /// 导航栏[导出]BarItem的响应事件
    /// - Parameter sender: BarItem对象
    @objc func exportNavBtnItemAction (sender: UIBarButtonItem) {
        /* ========== [显示]过渡动画,[关闭]用户交互 start ==========  */
        kMainWindow?.isUserInteractionEnabled = false
        self.view.makeToastActivity(.center)
        /* ========== [显示]过渡动画,[关闭]用户交互 end ==========  */
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let outputURL = NSURL(fileURLWithPath: "\(documentPath)/output.mp4") as URL
        self.videoClipsEditSuperView.exportVideoSource(outputURL: outputURL) { outputURL in
            /* ========== [隐藏]过渡动画,[开启]用户交互 start ==========  */
            kMainWindow?.isUserInteractionEnabled = true
            self.view.hideToastActivity()
            /* ========== [隐藏]过渡动画,[开启]用户交互 end ==========  */
            kLog(outputURL ?? "")
        }
    }

    
}

