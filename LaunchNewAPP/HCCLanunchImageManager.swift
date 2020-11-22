//
//  LanunchImageHelper.swift
//  HuiChaCha
//
//  Created by 张小杨 on 2020/11/4.
//  Copyright © 2020 Kinglin. All rights reserved.
//

import UIKit

class HCCLanunchImageManager: NSObject {
    
    static func snapShotStoryboard(sbName: String) -> UIImage? {
        guard !sbName.isEmpty else { return nil}
        let storyboard = UIStoryboard.init(name: sbName, bundle: nil)
        guard let vc = storyboard.instantiateInitialViewController() else { return  nil }
        vc.view.frame = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(vc.view.frame.size, false, UIScreen.main.scale)
        guard let context =  UIGraphicsGetCurrentContext() else { return nil}
        vc.view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    
    static func changeLaunchImage(selectImage: UIImage) {
        let selectedImage = resizeImage(image: selectImage)
        HCCLaunchImageHelper.replaceLaunchImage(replaceImage: selectedImage, compressionQuality: 0.8) { (oldImage, newImage) -> Bool in
            return checkImage(aImage: oldImage, sizeEqualToImage: newImage)
        }
    }
    
    static func resizeImage(image: UIImage) -> UIImage? {
        let imageSize = __CGSizeApplyAffineTransform(image.size, CGAffineTransform(scaleX: image.scale, y: image.scale))
        let contextSize: CGSize = contextSizeFormate()
        if !__CGSizeEqualToSize(imageSize, contextSize) {
            UIGraphicsBeginImageContext(contextSize)
            let ratio = max(contextSize.width / image.size.width, contextSize.height / image.size.height)
            let rect = CGRect.init(x: 0, y: 0, width: image.size.width * ratio, height: image.size.height * ratio)
            image.draw(in: rect)
            let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return resizeImage
        }
        return image
    }
    
    static func checkImage(aImage: UIImage, sizeEqualToImage: UIImage) -> Bool {
        return __CGSizeEqualToSize(obtainImageSize(image: aImage), obtainImageSize(image: sizeEqualToImage))
    }
    
    static func obtainImageSize(image: UIImage) -> CGSize {
        return CGSize.init(width: image.cgImage!.width, height: image.cgImage!.height)
    }
    
    static func contextSizeFormate() -> CGSize {
        let screenScale = UIScreen.main.scale
        let screenSize = UIScreen.main.bounds.size
        let width = min(screenSize.width, screenSize.height)
        let height = max(screenSize.width, screenSize.height)
        let contextSize = CGSize.init(width: width * screenScale, height: height * screenScale)
        return contextSize
    }
    
}
