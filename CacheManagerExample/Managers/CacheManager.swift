//
//  CacheManager.swift
//
//  Created by Fabio Acri on 21/04/2019.
//  Copyright © 2019 Fabio Acri. All rights reserved.
//

import Foundation
import UIKit

protocol MyCache {
    
    func get(imageAtURLString imageURLString: String, completionBlock: (UIImage?) -> Void)
    func set(_ object: Data, forKey key: String)
    func removeWholeCache() throws
    func getTotalCacheDiskSize() throws -> Double
    func getCacheTotalElements() -> Int
}

internal class ElementCachedModel {
    var imageName: String
    var counter: Int
    
    init(filename: String, counter: Int) {
        self.imageName = filename
        self.counter = counter
    }
}

final class CacheManager {
    
    /// Properties
    fileprivate let fileManager: FileManager
    fileprivate let maxElementsToCacheOnDisk: Int
    var elementsCachedData = [ElementCachedModel]()
    
    /// Constructor
    init(_ fileManager: FileManager = FileManager.default, _ maxElementsOnDisk: Int = 10000) {
        self.fileManager = fileManager
        self.maxElementsToCacheOnDisk = maxElementsOnDisk
        let cacheDir = getDocumentsDirectory().appendingPathComponent("Cache", isDirectory: true)
        do {
            _ = try fileManager.createDirectory(atPath: cacheDir.path, withIntermediateDirectories: false, attributes: nil)
        } catch (let error) {
            print("[CacheManager] problems creating directory Cache: \(error.localizedDescription)")
        }
    }
    
    /// Documents directory
    fileprivate func getDocumentsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    /// Cache directory in Documents
    fileprivate func getCacheDirectory() -> URL {
        return getDocumentsDirectory().appendingPathComponent("Cache", isDirectory: true)
    }
    
    /// Cache directory + /image file name
    fileprivate func imagePath(_ imageURLString: String) -> String {
        return getCacheDirectory().path.appending("/" + imageURLString)
    }
}

extension CacheManager: MyCache {
    
    /// gets image if exists in cache
    func get(imageAtURLString imageURLString: String, completionBlock: (UIImage?) -> Void) {
        let imageFile = imageURLString.components(separatedBy: "/").last ?? ""
        let locationPath = imagePath(imageFile)
        if fileManager.fileExists(atPath: locationPath) {
            logElementCached(imageFile)
            let validImage = UIImage(contentsOfFile: locationPath)
            completionBlock(validImage)
            return
        }
        
        completionBlock(nil)
    }
    
    func logElementCached(_ name: String) {
        
        for element in elementsCachedData {
            if element.imageName == name {
                element.counter += 1
                return
            }
        }
        
        elementsCachedData.append(ElementCachedModel(filename: name, counter: 1))
    }
    
    /// Requirement to uncache the lowest count of elements requested after cache limit has been reached
    func checkLeastCount() {
        guard getCacheTotalElements() >= maxElementsToCacheOnDisk else {
            return
        }
        
        // uncache the least element requested
        let lowestCount = elementsCachedData.min { a, b in a.counter < b.counter }?.counter
        if let validLowest = lowestCount {
            let allLowest = elementsCachedData.filter {
                $0.counter == validLowest
            }
            
            // guard not to delete all cache dir if all have same count value
            guard allLowest.count != elementsCachedData.count else { return }
            
            // uncache all lowest count elements
            allLowest.forEach { (element) in
                uncacheSpecificItem(element.imageName)
                elementsCachedData.removeAll(where: { (model) -> Bool in
                    model.imageName == element.imageName
                })
            }
        }
    }
    
    /// Cache image, do some check if it exceeds number of cache limit
    func set(_ object: Data, forKey key: String) {
        
        // take into consideration a new image will be added to cache directory
        if (getCacheTotalElements() + 1) > maxElementsToCacheOnDisk {
            checkLeastCount()
        }
        
        // creates file and log cached image count
        _ = fileManager.createFile(atPath: imagePath(key), contents: object, attributes: nil)
        logElementCached(key)
    }
    
    /// Remove entire cache
    func removeWholeCache() throws {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: getCacheDirectory().path)
            for pathComponent in contents {
                _ = try? fileManager.removeItem(atPath: imagePath(pathComponent))
            }
        } catch {
            print("[CacheManager] removeWholeCache() -> error retrieving elements in cache directory")
        }
        
    }
    
    /// Uncache specific item
    func uncacheSpecificItem(_ filename: String) {
        _ = try? fileManager.removeItem(atPath: imagePath(filename))
    }
    
    /// Calculates app disk cache size
    func getTotalCacheDiskSize() throws -> Double {
        var size: Double = 0
        let contents = try fileManager.contentsOfDirectory(atPath: getCacheDirectory().path)
        for pathComponent in contents {
            let attributes = try fileManager.attributesOfItem(atPath: imagePath(pathComponent))
            if let fileSize = attributes[.size] as? Double {
                size += fileSize
            }
        }
        return size / 1000.0
    }
    
    /// get the total elements in cache dir
    func getCacheTotalElements() -> Int {
        var contents = try? fileManager.contentsOfDirectory(atPath: getCacheDirectory().path)
        contents = contents?.filter { ($0.range(of: ".jpg") != nil) || ($0.range(of: ".png") != nil) }
        guard let allContents = contents else { return 0 }
        return allContents.count
    }
}
