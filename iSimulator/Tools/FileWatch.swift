import Foundation

final class FileWatch {
    struct EventFlag: OptionSet {
        let rawValue: FSEventStreamEventFlags
        init(rawValue: FSEventStreamEventFlags) {
            self.rawValue = rawValue
        }
        
        static let ItemRenamed = EventFlag(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed))
        static let ItemIsFile = EventFlag(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile))
    }
    
    enum Error: Swift.Error {
        case startFailed
        case streamCreateFailed
    }
    
    private let eventHandler: (EventFlag) -> Void
    
    private var eventStream: FSEventStreamRef?
    
    init(paths: [String], eventHandler: @escaping (EventFlag) -> Void) throws {
        self.eventHandler = eventHandler
        var ctx = FSEventStreamContext(version: 0, info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)
        
        
        
        guard let eventStream = FSEventStreamCreate(kCFAllocatorDefault,
                                                    FileWatch.StreamCallback,
                                                    &ctx,
                                                    paths as CFArray,
                                                    FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                                                    1,
                                                    17) else {
            throw Error.streamCreateFailed
        }
        
        FSEventStreamScheduleWithRunLoop(eventStream, RunLoop.current.getCFRunLoop(),
                                         CFRunLoopMode.defaultMode.rawValue)
        if !FSEventStreamStart(eventStream) {
            throw Error.startFailed
        }
        
        self.eventStream = eventStream
    }
    
    deinit {
        guard let eventStream = self.eventStream else {
            return
        }
        FSEventStreamStop(eventStream)
        FSEventStreamInvalidate(eventStream)
        FSEventStreamRelease(eventStream)
        self.eventStream = nil
    }
    
    private static let StreamCallback: FSEventStreamCallback = {(streamRef, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds) -> Void in
        Array(UnsafeBufferPointer(start: eventFlags, count: numEvents)).forEach { flag in
            unsafeBitCast(clientCallBackInfo, to: FileWatch.self).eventHandler(EventFlag(rawValue: flag))
        }
    }
}
