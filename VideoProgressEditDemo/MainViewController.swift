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
    lazy var videoProgressEditBodyView = {
        let myself = PEDTVideoProgressEditSuperView()
        return myself
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.customNavigationBar()
        
        let exportNavBtnItem = UIBarButtonItem.init(title: NSLocalizedString("导出", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(exportNavBtnItemAction))
        let cutoutNavBtnItem = UIBarButtonItem.init(title: NSLocalizedString("裁剪", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(cutoutNavBtnItemAction))
        self.navigationItem.rightBarButtonItems = [exportNavBtnItem, cutoutNavBtnItem]
        
        self.view.addSubview(self.videoProgressEditBodyView)
        self.videoProgressEditBodyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.videoProgressEditBodyView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: 0),
            self.videoProgressEditBodyView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor, constant: 0),
            self.videoProgressEditBodyView.widthAnchor.constraint(equalToConstant: kScreenWidth),
            self.videoProgressEditBodyView.heightAnchor.constraint(equalToConstant: kScreenWidth + 10 + 80)
        ])
        
        /* ========== [显示]过渡动画,[关闭]用户交互 start ==========  */
        kMainWindow?.isUserInteractionEnabled = false
        self.view.makeToastActivity(.center)
        /* ========== [显示]过渡动画,[关闭]用户交互 end ==========  */
        guard let videoAssetStr = Bundle.main.path(forResource: VideoName, ofType: "") else {
            return
        }
        let videoURL = NSURL(fileURLWithPath: videoAssetStr) as URL
        self.videoProgressEditBodyView.loadVideoSource(videoURL: videoURL) { [weak self] videoFrameModels in
            guard let self = self else {
                return
            }
            /* ========== [隐藏]过渡动画,[开启]用户交互 start ==========  */
            kMainWindow?.isUserInteractionEnabled = true
            self.view.hideToastActivity()
            /* ========== [隐藏]过渡动画,[开启]用户交互 end ==========  */
            
        }
    }
    
    
    
    
    /// 导航栏[裁剪]BarItem的响应事件
    /// - Parameter sender: BarItem对象
    @objc func cutoutNavBtnItemAction (sender: UIBarButtonItem) {
        
    }
    /// 导航栏[导出]BarItem的响应事件
    /// - Parameter sender: BarItem对象
    @objc func exportNavBtnItemAction (sender: UIBarButtonItem) {
        
    }

    
}

