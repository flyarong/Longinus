//
//  MemoryCache.swift
//  Longinus
//
//  Created by Qitao Yang on 2020/5/11.
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
    

import Foundation

public class MemoryCache<Key: Hashable, Value> {
    
    let releaseQueue = DispatchQueue.global(qos: .utility)
    
    private let lock: Mutex = Mutex()
    private var lru = LinkedList<Key, Value>()
    private var trimDict = [Key:TrimNode]()
    private let queue = DispatchQueue(label: "\(LonginusPrefixID).cache.memory")
    
    private(set) var countLimit: Int
    private(set) var costLimit: Int
    private(set) var ageLimit: CacheAge
    private(set) var autoTrimInterval: TimeInterval
    
    public private(set) var totalCost: Int = 0
    public var totalCount: Int {
        lock.lock()
        let count = self.lru.count
        lock.unlock()
        return count
    }
    
    public var shouldRemoveAllObjectsOnMemoryWarning: Bool = true
    public var shouldRemoveAllObjectsWhenEnteringBackground: Bool = true
    public var didReceiveMemoryWarningBlock: ((MemoryCache<Key,Value>)->Void)?
    public var didEnterBackgroundBlock: ((MemoryCache<Key,Value>)->Void)?
    public var releaseOnMainThread: Bool = false
    public var releaseAsynchronously: Bool = true
    
    var shouldAutoTrim: Bool {
        didSet {
            if oldValue == shouldAutoTrim { return }
            if shouldAutoTrim {
                autoTrim()
            }
        }
    }
    
    public var first: Value? {
        return lru.first
    }
    
    public var last: Value? {
        return lru.last
    }
    
    public init(countLimit: Int = Int.max, costLimit: Int = Int.max, ageLimit: CacheAge = .never, autoTrimInterval: TimeInterval = 5) {
        self.totalCost = 0
        self.countLimit = countLimit
        self.costLimit = costLimit
        self.ageLimit = ageLimit
        self.autoTrimInterval = autoTrimInterval
        self.shouldAutoTrim = self.autoTrimInterval > 0
        
        if shouldAutoTrim { autoTrim() }
        
        NotificationCenter.default.addObserver(self, selector: #selector(appDidReceiveMemoryWarningNotification), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Notification Methods
    @objc private func appDidReceiveMemoryWarningNotification() {
        self.didReceiveMemoryWarningBlock?(self)
        if self.shouldRemoveAllObjectsOnMemoryWarning {
            self.removeAll()
        }
    }

    @objc private func appDidEnterBackgroundNotification() {
        self.didEnterBackgroundBlock?(self)
        if self.shouldRemoveAllObjectsWhenEnteringBackground {
            self.removeAll()
        }
    }
    
}

extension MemoryCache: MemoryCacheable {
    public func containsObject(key: Key) -> Bool {
        return lru.contains(where: { $0 == key })
    }
    
    public func query(key: Key) -> Value? {
        lock.lock()
        self.trimDict[key]?.updateAge()
        let value = self.lru.value(for: key)
        lock.unlock()
        return value
    }
    
    // MARK: - save
    public func save(value: Value, for key: Key) {
        save(value: value, for: key, cost: 0)
    }
    
    public func save(value: Value, for key: Key, cost: Int = 0) {
        lock.lock()
        self.trimDict[key] = TrimNode(cost: cost)
        self.totalCost += cost
        
        self.lru.push(value, for: key)
        
        if self.totalCost > self.costLimit {
            self.queue.async { [weak self] in
                guard let self = self else { return }
                self.trimToCost(self.costLimit)
            }
        }
        if self.totalCount > self.countLimit {
            let trailNode = self.lru.removeTrail()
            if self.releaseAsynchronously {
                let queue = self.releaseOnMainThread ? DispatchQueue.main : self.releaseQueue
                queue.async {
                    let _ = trailNode?.key //hold and release in queue
                }
            } else if (self.releaseOnMainThread && pthread_main_np() == 0) {
                DispatchQueue.main.async {
                    let _ = trailNode?.key //hold and release in queue
                }
            }
        }
        lock.unlock()
    }
    
    // MARK: - remove
    public func remove(key: Key) {
        lock.lock()
        if let node = trimDict[key] {
            self.totalCost -= node.cost
            self.lru.remove(for: key)
            self.trimDict.removeValue(forKey: key)
            if self.releaseAsynchronously {
                let queue = self.releaseOnMainThread ? DispatchQueue.main : self.releaseQueue
                queue.async {
                    let _ = node //hold and release in queue
                }
            } else if (self.releaseOnMainThread && pthread_main_np() == 0) {
                DispatchQueue.main.async {
                    let _ = node //hold and release in queue
                }
            }
        }
        lock.unlock()
    }
    
    public func removeAll() {
        lock.lock()
        self.trimDict.removeAll()
        self.totalCost = 0
        self.lru.removeAll()
        lock.unlock()
    }
    
    public func setCostLimit(_ cost: Int) {
        lock.lock()
        self.costLimit = cost
        self.queue.async { [weak self] in
            self?.trimToCost(cost)
        }
        lock.unlock()
    }
    
    public func setCountLimit(_ count: Int) {
        lock.lock()
        self.countLimit = count
        self.queue.async { [weak self] in
            self?.trimToCount(count)
        }
        lock.unlock()
    }
    
    public func setAgeLimit(_ age: CacheAge) {
        lock.lock()
        self.ageLimit = age
        self.queue.async { [weak self] in
            self?.trimToAge(age)
        }
        lock.unlock()
    }
    
    private func removeLast() {
        lock.lock()
        if let key = self.lru.removeTrail()?.key,
            let cost = self.trimDict.removeValue(forKey: key)?.cost {
            self.totalCost -= cost
        }
        lock.unlock()
    }
}

extension MemoryCache: AutoTrimable {
    public func trimToCount(_ countLimit: Int) {
        let unlock: ()->Void = { [weak self] in self?.lock.unlock() }
        lock.lock()
        if countLimit <= 0 {
            self.removeAll()
            return unlock()
        } else if self.lru.count <= countLimit {
            return unlock()
        }
        unlock()
        
        while true {
            if self.lock.trylock() == 0 {
                if lru.count > countLimit,
                    !lru.isEmpty {
                    self.removeLast()
                } else {
                    return unlock()
                }
                self.lock.unlock()
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
    }
    
    public func trimToCost(_ costLimit: Int) {
        let unlock: ()->Void = { [weak self] in self?.lock.unlock() }
        lock.lock()
        if costLimit <= 0 {
            self.removeAll()
            return unlock()
        } else if self.totalCost <= costLimit {
            return unlock()
        }
        unlock()
        
        while true {
            if self.lock.trylock() == 0 {
                if totalCost > costLimit, totalCost > 0 {
                    self.removeLast()
                } else {
                    return unlock()
                }
                self.lock.unlock()
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
    }
    
    public func trimToAge(_ ageLimit: CacheAge) {
        let unlock: ()->Void = { [weak self] in self?.lock.unlock() }
        lock.lock()
        if ageLimit.timeInterval <= 0 {
            self.removeAll()
            return unlock()
        }
        unlock()
       
        let now = Date().timeIntervalSince1970
        while true {
            if self.lock.trylock() == 0 {
                if let lastNodeKey = lru.index(before: lru.endIndex).node?.key,
                    let lastTrimNode = trimDict[lastNodeKey],
                    now - lastTrimNode.age > ageLimit.timeInterval {
                    self.removeLast()
                } else {
                    return unlock()
                }
                self.lock.unlock()
            } else {
                usleep(10 * 1000) // 10 ms
            }
        }
    }
}

extension MemoryCache {
    private struct TrimNode: Hashable {
        private(set) var cost: Int
        private(set) var age: TimeInterval = Date().timeIntervalSince1970
        
        mutating func updateAge() {
            self.age = Date().timeIntervalSince1970
        }
        
        init(cost: Int) {
            self.cost = cost
        }
    }
}

extension MemoryCache: CustomStringConvertible {
    public var description: String {
        return lru.description
    }
}

