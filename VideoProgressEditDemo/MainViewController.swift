//
//  MainViewController.swift
//  SimpleProgramSwift
//
//  Created by Artanis Protoss on 2018/10/28.
//

import UIKit

class MainViewController: UIViewController {
    lazy var videoProgressEditBodyView = {
        let myself = PEDTVideoProgressEditBodyView()
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
            self.videoProgressEditBodyView.heightAnchor.constraint(equalToConstant: 80)
        ])
        
    }
    
    
    
    

    /// 导航栏[开始]BarItem的响应事件
    /// - Parameter sender: BarItem对象
    @objc func begainBtnAction (sender: UIBarButtonItem) {
        
    }
    /// 导航栏[返回]BarItem的响应事件
    /// - Parameter sender: BarItem对象
    @objc func backBtnAction (sender: UIBarButtonItem) {
        
    }
    
}

