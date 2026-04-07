import CoreGraphics
import Foundation

final class EventTapManager: @unchecked Sendable {
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let buffer: EventBuffer
    private let appResolver: FrontmostAppResolver
    private var tapThread: Thread?

    init(buffer: EventBuffer, appResolver: FrontmostAppResolver) {
        self.buffer = buffer
        self.appResolver = appResolver
    }

    func start() throws {
        let mask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: eventTapCallback,
            userInfo: refcon
        ) else {
            throw EventTapError.failedToCreate
        }

        eventTap = tap

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source

        let thread = Thread { [weak self] in
            guard let source = self?.runLoopSource else { return }
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.name = "com.keyboardlogger.eventtap"
        thread.qualityOfService = .utility
        tapThread = thread
        thread.start()
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource {
            CFRunLoopSourceInvalidate(source)
        }
        eventTap = nil
        runLoopSource = nil
        tapThread?.cancel()
        tapThread = nil
    }

    /// Called directly on the event tap thread — no Task hop, no main thread bounce.
    fileprivate func handleKeyEvent(_ event: CGEvent) {
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let appInfo = appResolver.current // lock-guarded read, no main thread needed

        let classified = KeyEventClassifier.classify(
            keyCode: keyCode,
            flags: flags,
            appBundleID: appInfo.bundleID,
            appName: appInfo.name
        )

        // Fire-and-forget into the actor — the only async hop
        Task { await self.buffer.append(classified) }
    }

    enum EventTapError: Error {
        case failedToCreate
    }
}

private func eventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard type == .keyDown, let refcon = refcon else {
        return Unmanaged.passRetained(event)
    }

    let manager = Unmanaged<EventTapManager>.fromOpaque(refcon).takeUnretainedValue()
    manager.handleKeyEvent(event)

    return Unmanaged.passRetained(event)
}
