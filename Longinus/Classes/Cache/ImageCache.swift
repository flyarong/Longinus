//
//  ImageCacher.swift
//  Longinus
//
//  Created by Qitao Yang on 2020/5/12.
//
//  Copyright (c) 2020 KittenYang <kittenyang@icloud.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import UIKit

public class ImageCacher: ImageCacheable {

    public let memoryCache: MemoryCache<String, UIImage>
    public let diskCache: DiskCache?
    public weak var imageCoder: ImageCodeable?
    
    init(path: String, sizeThreshold: Int) {
        memoryCache = MemoryCache()
        diskCache = DiskCache(path: path, sizeThreshold: sizeThreshold)
    }
    
    public func image(forKey key: String, cacheType: ImageCacheType, completion: @escaping (ImageCacheQueryCompletionResult) -> Void) {
        var memoryImage: UIImage?
        if cacheType.contains(.memory),
            let image = memoryCache.query(key: key) {
            if cacheType == .all {
                memoryImage = image
            } else {
                return completion(.memory(image: image))
            }
        }
        if cacheType.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.query(key: key) { (imageKey, imageData) in
                if let currentData = imageData {
                    if cacheType == .all,
                        let currentImage = memoryImage {
                        completion(.all(image: currentImage, data: currentData))
                    } else {
                        completion(.disk(data: currentData))
                    }
                } else if let currentImage = memoryImage {
                    // Cache type is all
                    completion(.memory(image: currentImage))
                } else {
                    completion(.none)
                }
            }
        }
        completion(.none)
    }
    
    public func diskDataExists(forKey key: String, completion: @escaping (Bool) -> Void) {
        guard let currentDiskCache = diskCache else { return completion(false) }
        currentDiskCache.containsObject(key: key) { (_, contain) in
            completion(contain)
        }
    }
    
    public func store(_ image: UIImage?, data: Data?, forKey key: String, cacheType: ImageCacheType, completion: @escaping ((
        ) -> Void)) {
        if cacheType.contains(.memory),
            let currentImage = image {
            memoryCache.save(value: currentImage, for: key, cost: currentImage.cacheCost)
        }
        if cacheType.contains(.disk),
            let currentDiskCache = diskCache {
            if let currentData = data {
                return currentDiskCache.save(value: currentData, for: key, completion)
            }
            return currentDiskCache.save({ [weak self] () -> Data? in
                guard let self = self else { return nil }
                if let currentImage = image,
                    let coder = self.imageCoder,
                    let data = coder.encodedData(with: currentImage, format: currentImage.lg.imageFormat ?? .unknown) {
                    return data
                }
                return nil
            }, forKey: key, result: completion)
        }
        completion()
    }
    
    public func removeImage(forKey key: String, cacheType: ImageCacheType, completion: @escaping  (String) -> Void) {
        if cacheType.contains(.memory) { memoryCache.remove(key: key) }
        if cacheType.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.remove(key: key, completion)
        }
        completion(key)
    }
    
    public func remove(_ type: ImageCacheType, completion: @escaping (() -> Void)) {
        if type.contains(.memory) { memoryCache.removeAll() }
        if type.contains(.disk),
            let currentDiskCache = diskCache {
            return currentDiskCache.removeAll(completion)
        }
        completion()
    }

}

