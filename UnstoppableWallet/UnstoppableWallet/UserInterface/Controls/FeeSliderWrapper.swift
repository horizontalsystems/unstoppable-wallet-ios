import UIKit
import HUD
import ComponentKit

class FeeSliderWrapper: UIView {
    private let slider = FeeSlider()
    private let decreaseButton = UIButton()
    private let increaseButton = UIButton()

    private let feeRateView = FeeSliderValueView()
    private var sliderLastValue: Int?
    private var step: Int = 1

    var finishTracking: ((Int) -> ())?

    var sliderRange: ClosedRange<Int> {
        Int(slider.minimumValue)...Int(slider.maximumValue)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    required init() {
        super.init(frame: CGRect.zero)

        addSubview(slider)
        addSubview(decreaseButton)
        addSubview(increaseButton)

        slider.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(decreaseButton.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalTo(increaseButton.snp.leading).offset(-CGFloat.margin2x)
        }
        slider.onTracking = { [weak self] value, position in
            self?.onTracking(value, position: position)
        }
        slider.finishTracking = { [weak self] value in
            self?.onFinishTracking(value)
        }
        slider.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        slider.setContentHuggingPriority(.defaultLow, for: .vertical)

        decreaseButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalTo(slider)
        }
        decreaseButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        decreaseButton.setImage(UIImage(named: "minus_2_20"), for: .normal)
        decreaseButton.addTarget(self, action: #selector(decrease), for: .touchUpInside)

        increaseButton.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview()
            maker.centerY.equalTo(slider)
        }
        increaseButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        increaseButton.setImage(UIImage(named: "plus_2_20"), for: .normal)
        increaseButton.addTarget(self, action: #selector(increase), for: .touchUpInside)

    }

    @objc private func decrease() {
        guard Int(slider.value) > Int(slider.minimumValue) else {
            return
        }
        slider.value = max(slider.value - Float(step), slider.minimumValue)

        finishTracking?(Int(slider.value))
    }

    @objc private func increase() {
        guard Int(slider.value) < Int(slider.maximumValue) else {
            return
        }
        slider.value = min(slider.value + Float(step), slider.maximumValue)

        finishTracking?(Int(slider.value))
    }

    func set(value: Int, range: ClosedRange<Int>, step: Int, description: String?) {
        slider.minimumValue = Float(range.lowerBound)
        slider.maximumValue = Float(range.upperBound)
        slider.value = Float(value)
        self.step = step

        feeRateView.set(descriptionText: description)
        sliderLastValue = value
    }

    private func hudConfig(position: CGPoint) -> HUDConfig {
        let hudWidth: CGFloat = 74
        var feeConfig = HUDConfig()

        feeConfig.appearStyle = .alphaAppear
        feeConfig.style = .banner(.top)
        feeConfig.absoluteInsetsValue = true
        feeConfig.userInteractionEnabled = true
        feeConfig.hapticType = .none
        feeConfig.blurEffectStyle = nil
        feeConfig.blurEffectIntensity = nil
        feeConfig.borderColor = .themeSteel20
        feeConfig.borderWidth = .heightOnePixel
        feeConfig.exactSize = true
        feeConfig.preferredSize = CGSize(width: hudWidth, height: 48)
        feeConfig.cornerRadius = CGFloat.cornerRadius2x
        feeConfig.handleKeyboard = .none
        feeConfig.inAnimationDuration = 0
        feeConfig.outAnimationDuration = 0

        let convertedPoint = convert(CGPoint(x: 0, y: -feeConfig.preferredSize.height - CGFloat.margin2x), to: nil)
        feeConfig.hudInset = CGPoint(x: position.x - center.x, y: convertedPoint.y)

        return feeConfig
    }

    private func onTracking(_ value: Int, position: CGPoint) {
        HUD.instance.config = hudConfig(position: position)

        feeRateView.set(value: "\(Decimal(value) / 1_000_000_000)")
        HUD.instance.showHUD(feeRateView)
    }

    private func onFinishTracking(_ value: Int) {
        HUD.instance.hide()

        guard sliderLastValue != value else {
            return
        }
        sliderLastValue = value

        finishTracking?(value)
    }

}
