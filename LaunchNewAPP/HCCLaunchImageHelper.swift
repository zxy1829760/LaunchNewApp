//
//  HCCLaunchImageHelper.swift
//  HuiChaCha
//
//  Created by 张小杨 on 2020/11/4.
//  Copyright © 2020 Kinglin. All rights reserved.
//

import UIKit

class HCCLaunchImageHelper: NSObject {
    typealias validateBlock = (_ originImage: UIImage, _ newImage: UIImage) -> Bool
            
    //系统启动图缓存路径
    static func launchImageCacheDirectory() -> String? {
        guard let bundleId = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") else { return nil }
        let fileManager = FileManager.default
        //iOS 13之前
        if #available(iOS 13.0, *) {
            let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first
            let libraryPath = libraryDirectory! as NSString
            let snapPath = libraryPath.appending("\(String(describing: libraryDirectory))/SplashBoard/Snapshots/\(bundleId) - {DEFAULT GROUP}")
            if fileManager.fileExists(atPath: snapPath) {
                return snapPath
            }
            
        } else {
            let cacheDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
            let cachePath = cacheDirectory! as NSString
            let snap = cachePath.appendingPathComponent("Snapshots") as NSString
            let snapPath = snap.appendingPathComponent(bundleId as! String)
            if fileManager.fileExists(atPath: snapPath) {
                return snapPath
            }
        }
        return nil
    }
    
    //系统缓存启动图的后缀名
    static func isSnapShotName(_ name: String) -> Bool {
        let newSystemSuffix = ".ktx"
        if name.hasSuffix(newSystemSuffix) {
            return true
        }
        let oldSystemSuffix = ".png"
        if name.hasSuffix(oldSystemSuffix) {
            return true
        }
        return false
    }
    
    //替换启动图
    static func replaceLaunchImage(replaceImage: UIImage?, compressionQuality: CGFloat, validateBlock: validateBlock) -> Bool {
        guard let replaceImg = replaceImage else { return false }
        //转为JPEG
        guard let imageData = replaceImg.jpegData(compressionQuality: compressionQuality) else { return false }
        
        //检查图片尺寸是否等同屏幕分辨率
        let isSame = checkImageScreenSize(image: replaceImg)
        if !isSame {return false}
        
        //获取系统缓存路径
        let cacheDir = launchImageCacheDirectory()
        if cacheDir?.isEmpty ?? true {return false}
        
        //工作目录
        let cacheDirPath: NSString = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first! as NSString
        let tempDir = cacheDirPath.appendingPathComponent("_tmpLaunchImageCaches")
        
        //清理工作目录
        let fm = FileManager.default
        if fm.fileExists(atPath: tempDir) {
            do{
                //尝试删除
                try fm.removeItem(atPath: tempDir)
            }catch{
            }
        }
        
        //移动系统缓存
        try! fm.moveItem(atPath: cacheDir!, toPath: tempDir)
        
        //操作工作记录,记录需要操作的图片名字
        var imageNames = [String]()
        let names = try! fm.contentsOfDirectory(atPath: tempDir)
        for i in 0..<names.count {
            if self.isSnapShotName(names[i]) {
                imageNames.append(names[i])
            }
        }
        
        //写入替换图片
        let tempDirP = tempDir as NSString
        for i in 0..<imageNames.count {
            let filePath = tempDirP.appendingPathComponent(imageNames[i])
            var result = true
            let cachedImgData = NSData.dataWithContentsOfMappedFile(filePath)
            let cacheImg = imageFromData(cachedImgData as! NSData)
            if (cacheImg != nil) {
                result = validateBlock(cacheImg!, replaceImg)
            }
            if result {
               try! imageData.write(to: URL(string: filePath)!)
            }
        }
        
        //还原系统缓存目录
        try! fm.moveItem(atPath: tempDir, toPath: cacheDir!)
        
        //清理缓存目录
        if fm.fileExists(atPath: tempDir) {
            do {
                try fm.removeItem(atPath: tempDir)
            } catch  {
            }
        }
        
        return true
        
    }
    
    // 检查图片大小
    static func checkImageScreenSize(image: UIImage) -> Bool {
        let screenSize = __CGSizeApplyAffineTransform(UIScreen.main.bounds.size, CGAffineTransform(scaleX: UIScreen.main.scale, y: UIScreen.main.scale))
        let imageSize = __CGSizeApplyAffineTransform(UIScreen.main.bounds.size, CGAffineTransform(scaleX: image.scale, y: image.scale))
        if __CGSizeEqualToSize(imageSize, screenSize) {
            return true
        }
        if __CGSizeEqualToSize(CGSize(width: imageSize.height, height: imageSize.width), screenSize) {
            return true
        }
        return false
    }
    
    //获取image对象
    static func imageFromData(_ data: NSData) -> UIImage? {
        guard let sourceImg = CGImageSourceCreateWithData(data, nil) else { return nil }
        let imageRef: CGImage? = CGImageSourceCreateImageAtIndex(sourceImg, 0, nil)
        if imageRef != nil {
            let originImage = UIImage.init(cgImage: imageRef!)
            return originImage;
        }
         return nil
    }
}
