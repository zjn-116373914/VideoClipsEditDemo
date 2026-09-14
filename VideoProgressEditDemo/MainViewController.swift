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
        self.title = NSLocalizedString("首页", comment: "")
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(title: NSLocalizedString("开始", comment: ""), style: UIBarButtonItem.Style.plain, target: self, action: #selector(begainBtnAction))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonItem.SystemItem.reply, target: self, action: #selector(backBtnAction))
        
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
            
            guard let firstFrameModel = videoFrameModels.first else {
                return
            }
            self.videoProgressEditBodyView.videoPlayImageView.image = PEDTVideoProgressEditHelper.imageWithPixelBuffer(pixelBuffer: firstFrameModel.pixelBuffer)
        }
    }
    
    
    
    

    /// 导航栏[开始]BarItem的响应事件
    /// - Parameter sender: BarItem对象
    @objc func begainBtnAction (sender: UIBarButtonItem) {
        self.videoProgressEditBodyView.readVideoSource()
    }
    /// 导航栏[返回]BarItem的响应事件
    /// - Parameter sender: BarItem对象
    @objc func backBtnAction (sender: UIBarButtonItem) {
        
    }
    
}

