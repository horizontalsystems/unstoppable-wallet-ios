import Foundation

class PeriodicTimer {
    weak var delegate: IPeriodicTimerDelegate?

    private let interval: TimeInterval
    private var timer: Timer?

    init(interval: TimeInterval) {
        self.interval = interval
    }

    deinit {
        timer?.invalidate()
    }

}

extension PeriodicTimer: IPeriodicTimer {

    func schedule() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { [weak self] _ in
            self?.delegate?.onFire()
        })

    }

}
