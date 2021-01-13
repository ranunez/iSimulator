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
    
    struct CreateFlag: OptionSet {
        let rawValue: FSEventStreamCreateFlags
        init(rawValue: FSEventStreamCreateFlags) {
            self.rawValue = rawValue
        }
        
        static let UseCFTypes = CreateFlag(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes))
        
        @available(OSX 10.7, *)
        static let FileEvents = CreateFlag(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents))
    }
    
    struct Event {
        let path: String
        let flag:  EventFlag
        let eventID: FSEventStreamEventId
    }
    
    enum Error: Swift.Error {
        case startFailed
        case streamCreateFailed
        case notContainUseCFTypes
    }
    
    private let eventHandler: (Event) -> Void
    
    private var eventStream: FSEventStreamRef?
    
    init(paths: [String], createFlag: CreateFlag, runLoop: RunLoop, latency: CFTimeInterval, eventHandler: @escaping (Event) -> Void) throws {
        self.eventHandler = eventHandler
        
        var ctx = FSEventStreamContext(version: 0, info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)
        
        if !createFlag.contains(.UseCFTypes) {
            throw Error.notContainUseCFTypes
        }
        
        guard let eventStream = FSEventStreamCreate(kCFAllocatorDefault, FileWatch.StreamCallback, &ctx, paths as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency, createFlag.rawValue) else {
            throw Error.streamCreateFailed
        }
        
        FSEventStreamScheduleWithRunLoop(eventStream, runLoop.getCFRunLoop(), CFRunLoopMode.defaultMode.rawValue)
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
        let `self` = unsafeBitCast(clientCallBackInfo, to: FileWatch.self)
        guard let eventPathArray = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else {
            return
        }
        let eventFlagArray = Array(UnsafeBufferPointer(start: eventFlags, count: numEvents))
        let eventIdArray   = Array(UnsafeBufferPointer(start: eventIds, count: numEvents))
        
        for i in 0..<numEvents {
            let path = eventPathArray[i]
            let flag = eventFlagArray[i]
            let eventID = eventIdArray[i]
            let event = Event(path: path, flag: EventFlag(rawValue: flag), eventID: eventID)
            self.eventHandler(event)
        }
    }
}
