import Foundation

struct SKQueueNotification: OptionSet {
    let rawValue: UInt32
    
    init(rawValue: UInt32) {
        self.rawValue = rawValue
    }
    
    static let Write            = SKQueueNotification(rawValue: 1 << 1)
    static let SizeIncrease     = SKQueueNotification(rawValue: 1 << 4)
    static let Default          = SKQueueNotification(rawValue: 0x7F)
}

final class SKQueuePath {
    let path: String
    let fileDescriptor: Int32
    var notification: SKQueueNotification
    
    init?(_ path: String, notification: SKQueueNotification) {
        self.path = path
        self.fileDescriptor = open((path as NSString).fileSystemRepresentation, O_EVTONLY, 0)
        self.notification = notification
        if self.fileDescriptor < 0 {
            return nil
        }
    }
    
    deinit {
        if self.fileDescriptor >= 0 {
            close(self.fileDescriptor)
        }
    }
}

final class SKQueue {
    private var kqueueId: Int32
    private var watchedPaths = [String: SKQueuePath]()
    private var keepWatcherThreadRunning = false
    typealias CallClosure = (_ notification: SKQueueNotification, _ path: String) -> Void
    private var callback:CallClosure
    
    init?(_ callback: @escaping CallClosure) {
        kqueueId = kqueue()
        if (kqueueId == -1) {
            return nil
        }
        self.callback = callback
    }
    
    deinit {
        keepWatcherThreadRunning = false
        removeAllPaths()
    }
    
    
    func addPath(_ path: String, notifyingAbout notification: SKQueueNotification = SKQueueNotification.Default) {
        if addPathToQueue(path, notifyingAbout: notification) == nil {
            NSLog("SKQueue tried to add the path \(path) to watchedPaths, but the SKQueuePath was nil. \nIt's possible that the host process has hit its max open file descriptors limit.")
        }
    }
    
    func removePath(_ path: String) {
        if let pathEntry = watchedPaths.removeValue(forKey: path) {
            Unmanaged<SKQueuePath>.passUnretained(pathEntry).release()
        }
    }
    
    func removeAllPaths() {
        watchedPaths.keys.forEach(removePath)
    }
    
    private func addPathToQueue(_ path: String, notifyingAbout notification: SKQueueNotification) -> SKQueuePath? {
        var pathEntry = watchedPaths[path]
        
        if pathEntry != nil {
            if pathEntry!.notification.contains(notification) {
                return pathEntry
            }
            pathEntry!.notification.insert(notification)
        } else {
            pathEntry = SKQueuePath(path, notification: notification)
            if pathEntry == nil {
                return nil
            }
            watchedPaths[path] = pathEntry!
        }
        
        var nullts = timespec(tv_sec: 0, tv_nsec: 0)
        
        var ev = kevent()
        ev.ident = UInt(pathEntry!.fileDescriptor)
        ev.filter = Int16(EVFILT_VNODE)
        ev.flags = UInt16(EV_ADD | EV_ENABLE | EV_CLEAR)
        ev.fflags = notification.rawValue
        ev.data = 0
        ev.udata = UnsafeMutableRawPointer(Unmanaged<SKQueuePath>.passRetained(watchedPaths[path]!).toOpaque())
        
        kevent(kqueueId, &ev, 1, nil, 0, &nullts)
        
        if !keepWatcherThreadRunning {
            keepWatcherThreadRunning = true
            DispatchQueue.global().async(execute: watcherThread)
        }
        
        return pathEntry
    }
    
    private func watcherThread() {
        var ev = kevent(), timeout = timespec(tv_sec: 20, tv_nsec: 0), fd = kqueueId
        
        while (keepWatcherThreadRunning) {
            let n = kevent(fd, nil, 0, &ev, 1, &timeout)
            if n > 0 && ev.filter == Int16(EVFILT_VNODE) && ev.fflags != 0 {
                let pathEntry = Unmanaged<SKQueuePath>.fromOpaque(ev.udata).takeUnretainedValue()
                let notification = SKQueueNotification(rawValue: ev.fflags)
                self.callback(notification, pathEntry.path)
            }
        }
        
        if close(fd) == -1 {
            NSLog("SKQueue watcherThread: Couldn't close main kqueue (%d)", errno)
        }
    }
}
