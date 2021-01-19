import Foundation

final class FileWatch {
    private struct EventFlag: OptionSet {
        let rawValue: FSEventStreamEventFlags
        init(rawValue: FSEventStreamEventFlags) {
            self.rawValue = rawValue
        }
        
        static let ItemRenamed = EventFlag(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed))
        static let ItemIsFile = EventFlag(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile))
    }
    
    private let eventHandler: (Bool) -> Void
    
    private var eventStream: FSEventStreamRef?
    
    init?(paths: [String], eventHandler: @escaping (Bool) -> Void) {
        self.eventHandler = eventHandler
        var ctx = FSEventStreamContext(version: 0, info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)
        
        
        
        guard let eventStream = FSEventStreamCreate(kCFAllocatorDefault,
                                                    FileWatch.StreamCallback,
                                                    &ctx,
                                                    paths as CFArray,
                                                    FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                                                    1,
                                                    17) else {
            return nil
        }
        
        FSEventStreamScheduleWithRunLoop(eventStream, RunLoop.current.getCFRunLoop(),
                                         CFRunLoopMode.defaultMode.rawValue)
        if !FSEventStreamStart(eventStream) {
            return nil
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
            let eventFlag = EventFlag(rawValue: flag)
            let shouldTriggerRefresh = eventFlag.contains(.ItemIsFile) && eventFlag.contains(.ItemRenamed)
            unsafeBitCast(clientCallBackInfo, to: FileWatch.self).eventHandler(shouldTriggerRefresh)
        }
    }
}
