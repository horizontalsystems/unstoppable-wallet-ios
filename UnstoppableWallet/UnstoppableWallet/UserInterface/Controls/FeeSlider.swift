import UIKit

class FeeSlider: UISlider {
    var onTracking: ((Int, CGPoint) -> ())?
    var finishTracking: ((Int) -> ())?

    private var lastValue: Int?

    required init() {
        let thumbImage: UIImage? = .circleImage(size: 18, color: .themeGray)
        let selectedThumbImage: UIImage? = .circleImage(size: 24, color: .themeGray)

        super.init(frame: CGRect.zero)

        setThumbImage(thumbImage, for: .normal)
        setThumbImage(selectedThumbImage, for: .highlighted)
        minimumTrackTintColor = .clear
        maximumTrackTintColor = .clear

        let slideBar = UIView()
        addSubview(slideBar)
        slideBar.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(4)
            maker.centerY.equalToSuperview().offset(1)
        }
        slideBar.backgroundColor = .themeSteel20
        slideBar.isUserInteractionEnabled = false
        slideBar.cornerRadius = .cornerRadius05x
        slideBar.clipsToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func correctCenter(touch: UITouch) -> CGPoint {     // touch position may be not in center of thumb, we need correct centerX
        touch.location(in: nil)
    }

    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)

        let intValue = Int(value)
        lastValue = intValue

        let position = correctCenter(touch: touch)

        onTracking?(intValue, position)

        return true
    }

    override open func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)

        let intValue = Int(value)
        if lastValue != intValue {
            lastValue = intValue
            let position = correctCenter(touch: touch)

            onTracking?(intValue, position)
        }

        return true
    }
    private func finish() {
        finishTracking?(lastValue ?? Int(value))
        lastValue = nil
    }

    override open func endTracking(_ touch: UITouch?, with event: UIEvent?)  {
        super.endTracking(touch, with: event)
        finish()
    }

    override open func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        finish()
    }

}
