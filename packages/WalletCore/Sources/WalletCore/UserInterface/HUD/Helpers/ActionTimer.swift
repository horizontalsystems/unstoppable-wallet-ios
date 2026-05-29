import Foundation

open class ActionTimer {
    var handler: (() -> Void)?

    public static func scheduledMainThreadTimer(action: (() -> Void)?, interval: TimeInterval, repeats: Bool = false, runLoopModes: RunLoop.Mode = RunLoop.Mode.common) -> Timer {
//        print("set timer : \(Date())")
        let handledTimer = ActionTimer()
        handledTimer.handler = action

        let timer = Timer(fireAt: Date(timeIntervalSinceNow: interval), interval: interval, target: handledTimer, selector: #selector(timerEvent), userInfo: nil, repeats: repeats)
        RunLoop.main.add(timer, forMode: runLoopModes)

        return timer
    }

    @objc func timerEvent() {
//        print("fire timer : \(Date())")
        handler?()
    }

    deinit {
//        print("deinit \(self)")
    }
}
