//
//  SPViewController+General.swift
//  SimpleProgramSwift
//
//  Created by Artanis Protoss on 20/8/2024.
//  Copyright © 2024 Artanis Protoss. All rights reserved.
//

import UIKit

extension UIViewController {
    func customNavigationBar() {
        if let myNavCtl = self.navigationController {
            let navigationBarAppearance = UINavigationBarAppearance()
            navigationBarAppearance.configureWithOpaqueBackground()
            navigationBarAppearance.backgroundColor = UIColor.white
            navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
            myNavCtl.navigationBar.standardAppearance = navigationBarAppearance
            myNavCtl.navigationBar.scrollEdgeAppearance = navigationBarAppearance
        }
    }
}
