import Foundation

class NotificationTimer {
    private var timer: Timer?

    weak var delegate: INotificationTimerDelegate?

    deinit {
        timer?.invalidate()
    }

    @objc func fire() {
        delegate?.onFire()
    }

}

extension NotificationTimer: INotificationTimer {

    func start(interval: TimeInterval) {
        timer?.invalidate()

        timer = Timer(fireAt: Date(timeIntervalSinceNow: interval), interval: 0, target: self, selector: #selector(fire), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .common)
    }

}
