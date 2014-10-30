import Foundation
import UIKit

public enum ImageLoaderLoadedFrom {
    case Memory
    case Disk
    case Network
}

class ImageLoaderOptions {
    let displayer: ImageLoaderDisplayer
    let processor: ImageLoaderProcessor
    
    init() {
        self.displayer = SimpleDisplayer()
        self.processor = SimpleProcessor()
    }
    
    init(displayer: ImageLoaderDisplayer, processor: ImageLoaderProcessor) {
        self.displayer = displayer
        self.processor = processor
    }
}

class ImageLoaderRequest {
    let url: NSURL
    let imageView: UIImageView
    let options: ImageLoaderOptions
    let cacheKey: String
    
    init(url: NSURL, imageView: UIImageView, options: ImageLoaderOptions) {
        self.url = url
        self.imageView = imageView
        self.options = options
        self.cacheKey = url.absoluteString! + options.processor.cacheKey(imageView)
    }
    
    func display(image: UIImage, loadedFrom: ImageLoaderLoadedFrom) {
        dispatch_async(dispatch_get_main_queue(), {
            self.options.displayer.display(image, imageView: self.imageView, loadedFrom: loadedFrom)
        })
    }
}

class ImageLoaderMemoryCache {
    struct Static {
        static let instance = ImageLoaderMemoryCache()
    }
    var cache = NSCache()
    
    class func get(key: String) -> NSData? {
        return Static.instance.cache.objectForKey(key) as? NSData
    }
    
    class func set(key: String, data: NSData) {
        Static.instance.cache.setObject(data, forKey: key)
    }
}

class ImageLoader {
    
    struct Static {
        private static let queue = NSOperationQueue()
        private static let serial = dispatch_queue_create("ImageLoader.Static.instance.serial_queue", DISPATCH_QUEUE_SERIAL)
        private static var requests = [String: [ImageLoaderRequest]]()
        private static var defaultOptions = ImageLoaderOptions()
        private static var imageViewState = [Int: String]()
    }
    
    class func setup(maxConcurrentCount: Int = 5, cacheLimit: Int = 100, options: ImageLoaderOptions? = nil) {
        Static.queue.maxConcurrentOperationCount = maxConcurrentCount
        
        ImageLoaderMemoryCache.Static.instance.cache.countLimit = cacheLimit
        
        if let newOptions = options {
            Static.defaultOptions = newOptions
        }
    }
    
    class func displayImage(url: NSURL, imageView: UIImageView) {
        displayImage(url, imageView: imageView, options: Static.defaultOptions)
    }
    
    class func displayImage(url: NSURL, imageView: UIImageView, options: ImageLoaderOptions) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, UInt(0)), { ()->() in
            let request = ImageLoaderRequest(url: url, imageView: imageView, options: options)
            
            dispatch_sync(Static.serial) {
                Static.imageViewState[imageView.hashValue] = request.cacheKey
            }
            
            if let data = ImageLoaderMemoryCache.get(request.cacheKey) {
                ImageLoader.doSuccess(request, data: data, loadedFrom: .Memory)
                return
            }
            
            dispatch_sync(Static.serial) {
                if let requests = Static.requests[request.cacheKey] {
                    Static.requests[request.cacheKey] = requests + [request]
                } else {
                    Static.requests[request.cacheKey] = [request]
                    let task = ImageLoaderTask(request)
                    Static.queue.addOperation(task.operation!) // Download from Network
                }
            }
        })
    }
    
    class func doSuccess(request: ImageLoaderRequest, data: NSData, loadedFrom: ImageLoaderLoadedFrom) {
        let image = transformIfNeed(request, data: data, loadedFrom: loadedFrom)
        
        switch (loadedFrom) {
        case .Network:
            ImageLoaderMemoryCache.set(request.cacheKey, data: UIImagePNGRepresentation(image))
        case .Disk:
            ImageLoaderMemoryCache.set(request.cacheKey, data: UIImagePNGRepresentation(image))
            request.display(image, loadedFrom: .Disk)
        case .Memory:
            request.display(image, loadedFrom: .Memory)
        }
        
        dispatch_sync(Static.serial) {
            if let requests = Static.requests.removeValueForKey(request.cacheKey) {
                for request in requests.filter({ h in Static.imageViewState[h.imageView.hashValue] == request.cacheKey }) {
                    request.display(image, loadedFrom: loadedFrom)
                    Static.imageViewState.removeValueForKey(request.imageView.hashValue)
                }
            }
        }
    }
    
    class func doFailure(request: ImageLoaderRequest) {
        dispatch_sync(Static.serial) {
            if let requests = Static.requests.removeValueForKey(request.cacheKey) {
                for request in requests.filter({ h in Static.imageViewState[h.imageView.hashValue] == request.cacheKey }) {
                    Static.imageViewState.removeValueForKey(request.imageView.hashValue)
                }
            }
        }
    }
    
    class func transformIfNeed(request: ImageLoaderRequest, data: NSData, loadedFrom: ImageLoaderLoadedFrom) -> UIImage {
        if loadedFrom == .Network {
            return request.options.processor.transform(data, imageView: request.imageView)
        } else {
            return UIImage(data: data)!
        }
    }
}

class ImageLoaderDownloadOperation: AsyncOperation {
    
    let task: NSURLSessionDownloadTask
    
    init(_ task: NSURLSessionDownloadTask) {
        self.task = task
        super.init()
    }
    
    override func start() {
        super.start()
        state = .Executing
        task.resume()
    }
    
    override func cancel() {
        super.cancel()
        state = .Finished
        task.cancel()
    }
    
    func finish() {
        state = .Finished
    }
    
}

class ImageLoaderTask: NSObject, NSURLSessionDownloadDelegate {
    
    let request: ImageLoaderRequest
    var operation: ImageLoaderDownloadOperation?
    
    init(_ request: ImageLoaderRequest) {
//        NSLog("%@ download init", request.cacheKey)
        
        self.request = request
        super.init()
        
        let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(request.cacheKey + String(NSDate().hashValue))
        let session = NSURLSession(configuration: config, delegate: self, delegateQueue: nil)
        
        operation = ImageLoaderDownloadOperation(session.downloadTaskWithURL(request.url))
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
//        NSLog("%@ download success", request.cacheKey)
        
        let data = NSData(contentsOfURL: location)
        if data != nil && data?.length > 0 {
            ImageLoader.doSuccess(request, data: data!, loadedFrom: .Network)
            operation?.finish()
        } else {
            operation?.cancel()
        }
        operation = nil
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let e = error {
            NSLog("%@ download error:%@", request.cacheKey, e.debugDescription)
            ImageLoader.doFailure(request)
        }
    }
    
}
