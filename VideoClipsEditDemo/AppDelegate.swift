//
//  AppDelegate.swift
//  SimpleProgramSwift
//
//  Created by Artanis Protoss on 2018/10/28.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        guard let keyWindow = self.window else {
            return false
        }
        
        let mainViewCtl = MainViewController()
        let mainNavCtl = UINavigationController(rootViewController: mainViewCtl)
        keyWindow.rootViewController = mainNavCtl
        keyWindow.backgroundColor = UIColor.white
        keyWindow.makeKeyAndVisible()
        
        return true
    }


}

