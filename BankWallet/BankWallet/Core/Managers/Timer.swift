import Foundation

class Timer {
    weak var delegate: ITimerDelegate?

    init(interval: TimeInterval) {
//        delegate?.onFire()
    }

}

extension Timer: ITimer {

    func start() {

    }

}
