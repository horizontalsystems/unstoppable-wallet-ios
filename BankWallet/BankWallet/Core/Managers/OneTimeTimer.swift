import Foundation

class OneTimeTimer {
    weak var delegate: IPeriodicTimerDelegate?

    private var timer: Timer?

    deinit {
        timer?.invalidate()
    }

    @objc func fire() {
        delegate?.onFire()
    }
}

extension OneTimeTimer: IOneTimeTimer {

    func schedule(date: Date) {
        timer?.invalidate()

        timer = Timer(fireAt: date, interval: 0, target: self, selector: #selector(fire), userInfo: nil, repeats: false)
        RunLoop.main.add(timer!, forMode: .common)
    }

}
