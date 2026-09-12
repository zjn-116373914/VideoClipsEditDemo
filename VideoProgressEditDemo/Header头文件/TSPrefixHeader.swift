//
//  TSPrefixHeader.swift
//  SimpleProgramSwift
//
//  Created by Artanis Protoss on 2018/10/28.
//  Copyright © 2024 Artanis Protoss. All rights reserved.
//

import UIKit

/// 当前设备是否为iPad
let kISiPad = UIDevice.current.model == "iPad"
/// 当前设备是否为iPhoneX类刘海屏设备
let kISiPhoneX = {
    if #available(iOS 11.0, *) {
        if (kISiPad == true) {
            return false
        }
        
        guard let safeAreaInsets = UIApplication.shared.delegate?.window??.safeAreaInsets else {
            return false
        }
        return safeAreaInsets.bottom > 0
    }
    return false
}()

/// 当前设备[屏幕宽度]
let kScreenWidth = UIScreen.main.bounds.width
/// 当前设备[屏幕高度]
let kScreenHeight = UIScreen.main.bounds.height
/// 当前设备[状态栏]高度 (时间/电量显示区域)
let kStatusHeight = kISiPad ? 44.0 : 20.0
/// [导航栏]高度
let kNavigationItemHeight = 44.0
/// [底部菜单栏]高度
let kTabBarItemHeight = 49.0

/// 设置RGBA颜色
func kRGBA(red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat) -> UIColor {
    let color: UIColor = UIColor.init(red: red/255.0, green: green/255.0, blue: blue/255.0, alpha: alpha)
    return color
}

/// 16进制颜色值(RGBA)
func kHexRGBA(hexStr: String) -> UIColor {
    let color:UIColor = UIColor.init(hexAString: hexStr)
    return color
}
/// 16进制颜色值(RGB和alpha)
func kHexRGB_alpha(hexStr: String, alpha: Float) -> UIColor {
    let color:UIColor = UIColor.init(hexString: hexStr, alpha: alpha)
    return color
}

/// 获取项目包内文件路径
func kBundleFile(fileName: String, fileType: String) -> String {
    let filePath = Bundle.main.path(forResource: fileName, ofType: fileType)
    if (filePath != nil) {
        return filePath!
    }
    return ""
}

/// 打印日志
func kLog (_ items: Any...,
            separator: String = " ",
            terminator: String = "\n",
            _ file:String = #file,
            _ function:String = #function,
            _ line:Int = #line) {
    #if DEBUG // 判断是否在测试环境下
    //获取日志内容
    var text = String()
    for subStr in items {
        text = text + "\(subStr)"
    }
    //获取日期
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss"
    dateFormatter.timeZone = NSTimeZone(name: "Asia/BeiJing") as TimeZone?
    let dateStr = dateFormatter.string(from: Date())
    //获取类名
    let className = (file as NSString).lastPathComponent
    debugPrint("\(dateStr) [\(className)][\(line)] [\(function)]|| log => \(text)")
    #else
    //Release环境不打印日志,提高运行速度
    #endif
}

/// App名称
let kAppName: String = {
    let appName: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
    return appName
}()

/// 获取App版本号
let kVersion: String = {
    let infoDict:NSDictionary = Bundle.main.infoDictionary! as NSDictionary
    let version = infoDict["CFBundleShortVersionString"];
    return version as! String
}()

/// 主体Window窗口
let kMainWindow: UIWindow? = {
    guard let mainWindow = UIApplication.shared.windows.first else {
        kLog("无法获取主体Window")
        return nil
    }
    return mainWindow
}()

/// 主体AppDelegate应用代理
let kAppDelegate: AppDelegate? = {
    guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
        kLog("无法获取主体AppDelegate")
        return nil
    }
    return appDelegate
}()

