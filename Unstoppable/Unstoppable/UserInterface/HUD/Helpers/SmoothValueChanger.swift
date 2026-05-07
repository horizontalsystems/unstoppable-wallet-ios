import Foundation

public class SmoothValueChanger {
    var currentValue: Float

    let fullChangeTime: TimeInterval
    let stepValue: Float

    var onChangeValue: ((Float) -> Void)?
    var onFinishChanging: ((Float) -> Void)?

    private var timer: Timer?

    public init(initialValue: Float, fullChangeTime: TimeInterval, stepValue: Float = 0.01, onChangeValue: ((Float) -> Void)?, onFinishChanging: ((Float) -> Void)? = nil) {
        currentValue = initialValue
        self.stepValue = stepValue
        self.fullChangeTime = fullChangeTime
        self.onChangeValue = onChangeValue
        self.onFinishChanging = onFinishChanging
    }

    public func set(value: Float) {
        timer?.invalidate()
        timer = nil

        if value > currentValue {
            let timeByStep = fullChangeTime * TimeInterval(stepValue)
            timer = ActionTimer.scheduledMainThreadTimer(action: { [weak self] in
                guard let currentValue = self?.currentValue else {
                    self?.timer?.invalidate()
                    self?.timer = nil
                    return
                }
                if currentValue >= value {
                    // finish change value
                    self?.finishChangeValue()
                } else {
                    self?.changeValue()
                }
            }, interval: timeByStep, repeats: true)
        }
    }

    private func finishChangeValue() {
//        print("timer finish change value with \(currentValue)")
        onFinishChanging?(currentValue)
        timer?.invalidate()
        timer = nil
    }

    private func changeValue() {
        currentValue += stepValue
//        print("timer change value to \(currentValue)")
        onChangeValue?(currentValue)
    }

    deinit {
//        print("deinit value changer")
    }
}
