//
//  ImageLoader.swift
//
//  Created by Fabio Acri on 18/04/2019.
//  Copyright © 2019 Fabio Acri. All rights reserved.
//

import Foundation
import UIKit

protocol ImageLoaderProtocol {
    func loadImage(with url: String, completionHandler: @escaping (UIImage?, Error?) -> Void) throws
}

final class ImageLoader: ImageLoaderProtocol {
    
    let cacheManager: MyCache
    
    init(_ cacheManager: MyCache = CacheManager()) {
        self.cacheManager = cacheManager
    }
    
    func loadImage(with url: String, completionHandler: @escaping (UIImage?, Error?) -> Void) throws {
        
        guard let validUrl = URL(string: url) else {
            throw NetworkRequestErrors.invalidUrl
        }
        
        DispatchQueue.global().async {
            
            // check if cache contains image first
            self.cacheManager.get(imageAtURLString: validUrl.absoluteString) { (image) in
                if let validImage = image {
                    completionHandler(validImage, nil)
                } else {
                    // proceed downloading image
                    self.downloadImage(validUrl, completionHandler)
                }
            }
        }
    }
    
    private func downloadImage(_ validURL: URL, _ completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        do {
            let imgData = try Data(contentsOf: validURL, options: .mappedIfSafe)
            
            guard let validImage = UIImage(data: imgData) else {
                throw NetworkRequestErrors.invalidImageData
            }
            
            // store the image in the cache
            cacheManager.set(imgData, forKey: validURL.pathComponents.last ?? "image")
            
            completionHandler(validImage, nil)
            
        } catch (let error) {
            print(error.localizedDescription)
            completionHandler(nil, nil)
        }
    }
    
}


