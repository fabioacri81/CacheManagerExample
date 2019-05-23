//
//  HomeScreenInteractor.swift
//
//  Created by Fabio Acri on 18/04/2019.
//  Copyright © 2019 Fabio Acri. All rights reserved.
//

import Foundation
import UIKit

enum NetworkRequestErrors: Error, Equatable {
    
    case invalidUrl
    case invalidImageData
    case invalidNetworkRequest
    case invalidJSONObjectEncoding
    
    func errorMsg() -> String {
        switch self {
        case .invalidUrl:
            return "Invalid URL!"
        case .invalidNetworkRequest:
            return "Invalid network request!"
        case .invalidJSONObjectEncoding:
            return "Invalid JSON encoding"
        case .invalidImageData:
            return "Invalid Image data"
        }
    }
    
    public static func == (lhs: NetworkRequestErrors, rhs: NetworkRequestErrors) -> Bool {
        return lhs.errorMsg() == rhs.errorMsg()
    }
}

final class ScreenInteractor: InteractorProtocol {
    
    // MARK: - Properties
    private var imageLoader: ImageLoaderProtocol?
    
    // MARK: - Methods
    
    /// getImage
    /// - Parameters:
    ///     - url: image url string to load
    ///     - completionHandler: completion data to return ( UIImage, Error )
    func getImage(with url: String, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        
        // init image loader if nil, don't want to inject in the initializer of the interactor, as image loader should be an independent component
        if imageLoader == nil {
            initImageLoader(ImageLoader())
        }
        
        // load image from ImageLoader, return results on main thread
        do {
            _ = try imageLoader?.loadImage(with: url, completionHandler: { (image, error) in
                DispatchQueue.main.async {
                    completionHandler(image, nil)
                }
            })
        } catch (let error) {
            print(error.localizedDescription)
        }
    }
    
    func initImageLoader(_ imageLoader: ImageLoaderProtocol) {
        self.imageLoader = imageLoader
    }
    
}
