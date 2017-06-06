//
//  Utils.swift
//  Homehapp
//
//  Created by DEVELOPER on 25/10/15.
//  Copyright © 2015 Homehapp. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import Photos

let HHUtilsErrorDomain = "HHUtilsErrorDomain"
let HHUtilsVideoEncodeFailed = -100
let HHUtilsCouldNotGetAssetURL = -101

/**
 Asynchronously executes a task in a background queue.
 
 - parameter task: Task to be executed
 */
public func runInBackground(_ task: @escaping ((Void) -> Void)) {
    DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: task)
}

/**
 Asynchronously executes a task in the main thread. If the calling thread is
 the main thread itself, the task is executed immediately.
 
 - parameter task: Task to be executed
 */
public func runOnMainThread(_ task: @escaping ((Void) -> Void)) {
    if Thread.isMainThread {
        // Already on main UI thread - call directly
        task()
    } else {
        DispatchQueue.main.async(execute: task)
    }
}

/**
 Executes a task on the main queue (UI thread) after a given delay.
 
 - parameter delay: Delay in seconds
 - parameter task: Task to be executed
 */
public func runOnMainThreadAfter(_ delay: TimeInterval, task: @escaping ((Void) -> Void)) {
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: task)
}

/**
 Calculates the required downscale ratio for an image in a way that the 
 image returned from Cloudinary is not larger than the max image size set to 
 ImageCache's shared instance.
 
 If the max size is not defined or the image is already smaller, the original url is returned.
 
 Getting a scaled version of a cloudinary image url is to add width parameter as such: 

 http://res.cloudinary.com/demo/image/upload/w_0.6/sample.jpg
*/
func scaledCloudinaryUrl(_ width: Int, height: Int, url: String, maxSize: CGSize? = nil) -> String {
//    guard let maxSize = maxSize ?? ImageCache.sharedInstance().maximumImageDimensions else {
        return url
//    }
    
    let width = CGFloat(width)
    let height = CGFloat(height)
    
    if (width < maxSize!.width) && (height < maxSize!.height) {
        
        // Let's always make sure exif information and orientation considered if we dont't scale image in cloudinary
        let rotatedUrl = url.replacingOccurrences(of: "/upload/", with: "/upload/a_exif/")
        return rotatedUrl
    }

    let widthRatio = width / maxSize!.width
    let heightRatio = height / maxSize!.height
    let scale = 1.0 / max(widthRatio, heightRatio)
    let scaleFormat = "w_\(scale)"
    let scaledUrl = url.replacingOccurrences(of: "/upload/", with: "/upload/\(scaleFormat)/")
    
    return scaledUrl
}

/// Return scaled Cloudinary url for home cover images in main list and home story header
func scaledCloudinaryCoverImageUrl(_ width: Int, height: Int, url: String) -> String {    
    let width = CGFloat(width)
    let height = CGFloat(height)
    
    let screenBounds = UIScreen.main.bounds
    let screenScale = UIScreen.main.scale
    let screenPixels = CGSize(width: screenBounds.size.width * screenScale, height: max(1000, screenBounds.size.height * screenScale));
    
    if (width < screenPixels.width) && (height < screenPixels.height) {
        let rotatedUrl = url.replacingOccurrences(of: "/upload/", with: "/upload/a_exif/")
        return rotatedUrl
    }
    
    let widthRatio = width / screenPixels.width
    let heightRatio = height / screenPixels.height
    let scale = 1.0 / max(widthRatio, heightRatio)
    let scaleFormat = "w_\(scale)"
    let scaledUrl = url.replacingOccurrences(of: "/upload/", with: "/upload/\(scaleFormat)/")
    
    return scaledUrl
}

/// Returns a snapshot image for a local video asset, taken as a snapshot from the start of the video
func getVideoSnapshot(_ videoUrl: URL) -> UIImage? {
    do {
        let asset = AVURLAsset(url: videoUrl, options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(0, 1), actualTime: nil)
        
        return UIImage(cgImage: cgImage)
    } catch let error {
        print("Failed to get snapshot for video; error: \(error)")
        return nil
    }
}

/**
 Asynchronously get downsampled video data from an AVAssetExportSession.
 The caller should delete the file at videoFileUrl once it is no longer needed.
 The callback will be called on the main thread.
*/
private func requestVideoDataForExportSession(_ exportSession: AVAssetExportSession, callback: @escaping ((_ videoFileUrl: URL?, _ error: NSError?) -> Void)) {
    let startTime = Date()
    
    // Allocate a temporary file to write to
    let tempFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
    
    // Configure the export session
    exportSession.canPerformMultiplePassesOverSourceMediaData = true
    exportSession.outputFileType = AVFileTypeMPEG4
    exportSession.outputURL = URL(fileURLWithPath: tempFilePath)
    
    exportSession.exportAsynchronously() {
        print("Video export completed, status: \(exportSession.status), error: \(exportSession.error)")
        
        if exportSession.status == .completed {
            print("Video encoding OK, the process took \(-startTime.timeIntervalSinceNow) seconds")
            
            runOnMainThread {
                // Callback on main thread
                callback(exportSession.outputURL, nil)
            }
        } else {
            runOnMainThread {
                // Callback on main thread
                if let error = exportSession.error {
                    callback(nil, error as NSError?)
                } else {
                    callback(nil, NSError(domain: HHUtilsErrorDomain, code: HHUtilsVideoEncodeFailed, userInfo: nil))
                }
            }
        }
    }
}

/** 
 Asynchronously get downsampled video data for a AVAsset url.
 The caller should delete the file at videoFileUrl once it is no longer needed.
 The callback will be called on the main thread.
*/
func requestVideoDataForAssetUrl(_ url: URL, callback: @escaping ((_ videoFileUrl: URL?, _ error: NSError?) -> Void)) {
    let asset = AVAsset(url: url)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
        callback(nil, NSError(domain: HHUtilsErrorDomain, code: HHUtilsVideoEncodeFailed, userInfo: nil))
        return
    }
    
    requestVideoDataForExportSession(exportSession, callback: callback)
}

/** 
 Asynchronously get image data for AVAsset url.
 The callback will be called on the main thread.
*/
func requestImageDataForAssetUrl(_ url: URL, callback: @escaping ((_ imageData: Data) -> Void)) {
    let fetchResult = PHAsset.fetchAssets(withALAssetURLs: [url], options: nil)
    //TODO : XCODE 8
//    if let phAsset = fetchResult.firstObject as? PHAsset {
//        PHImageManager.default().requestImageData(for: phAsset, options: nil) {
//            (imageData, dataURI, orientation, info) -> Void in
//            if let data = imageData {
//                runOnMainThread {
//                    callback(imageData: data)
//                }
//            }
//        }
//    }
}


/** 
 Asynchronously gets an asset url for a video
 The callback will be called on the main thread.
*/
func requestAssetVideoUrl(_ asset: PHAsset, callback: @escaping (_ assetUrl: URL?, _ error: NSError?) -> Void) {
    let options = PHVideoRequestOptions()
    options.deliveryMode = .highQualityFormat
    
    // enable access to iCloud if video is only there
    options.isNetworkAccessAllowed = true
    
    PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (avAsset, avAudioMix, info) in
        runOnMainThread {
            if let urlAsset = avAsset as? AVURLAsset {
                callback(urlAsset.url, nil)
            } else {
                callback(nil, NSError(domain: HHUtilsErrorDomain, code: HHUtilsCouldNotGetAssetURL, userInfo: nil))
            }
        }
    }
}

/// Asynchronously gets an UIImage out of a PHAsset object
func requestAssetImage(_ asset: PHAsset, scaleFactor: CGFloat = 1.0, callback: @escaping ((_ image: UIImage?) -> Void)) {
    let options = PHImageRequestOptions()
    options.resizeMode = PHImageRequestOptionsResizeMode.exact;
    options.version = PHImageRequestOptionsVersion.current;
    options.isNetworkAccessAllowed = true
    
    let targetSize = CGSize(width: scaleFactor * CGFloat(asset.pixelWidth), height: scaleFactor * CGFloat(asset.pixelHeight))

    PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options,
        resultHandler: {(image, info) in
            if let isDegraded = info?[PHImageResultIsDegradedKey] as? NSNumber , isDegraded.boolValue {
                // This is a temporary image; skip it
                return
            }
            
            if image == nil {
                if let error = info?[PHImageErrorKey] as? NSError {
                    print("Failed to extract UIImage out of PHAsset, error: \(error)")
                }
            }
            
            runOnMainThread {
                callback(image)
            }
    })
}

/**
 Get JPG assets-library-url for given asset
 http://stackoverflow.com/questions/28887638/how-to-get-an-alasset-url-from-a-phasset
 */
func getJPGAssetUrl(_ asset: PHAsset) -> String {
//    return "assets-library://asset/asset.JPG?id=\(asset.localIdentifier.substring(startIndex: 0, length: 36))&ext=JPG"
    let str  = ""
    return str
}

/// Make a shallow copy of a CachedImageView
//func copyCachedImageView(source: CachedImageView) -> CachedImageView {
//    let imageView = CachedImageView(frame: source.frame)
//    imageView.contentMode = source.contentMode
//    imageView.transform = source.transform
//    imageView.thumbnailData = source.thumbnailData
//    imageView.fadeInColor = source.fadeInColor
//    imageView.imageCache = source.imageCache
//    imageView.image = source.image
//    imageView.imageUrl = source.imageUrl
//    
//    return imageView
//}

/// Returns a (default) localized error message for a remote response
//func localizedErrorMessage(response: RemoteResponse) -> String? {
//    if response.success {
//        return nil
//    } else {
//        guard let remoteError = response.remoteError else {
//            log.error("remoteError not set!")
//            assert(false, "remoteError not set!")
//            return nil
//        }
//        
//        switch remoteError {
//        case .NetworkError:
//            return NSLocalizedString("errormsg:network", comment: "")
//        case .NetworkTimeout:
//            return NSLocalizedString("errormsg:network-timeout", comment: "")
//        default:
//            return NSLocalizedString("errormsg:server", comment: "")
//        }
//    }
//}
