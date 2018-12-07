import Foundation

class PeriodicTimer {
    weak var delegate: IPeriodicTimerDelegate?

    private let interval: TimeInterval
    private let repeats: Bool
    private var timer: Timer?

    init(interval: TimeInterval, repeats: Bool = false) {
        self.interval = interval
        self.repeats = repeats
    }

    deinit {
        timer?.invalidate()
    }

}

extension PeriodicTimer: IPeriodicTimer {

    func schedule() {
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: repeats, block: { [weak self] _ in
            self?.delegate?.onFire()
        })

    }

}
