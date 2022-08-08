import UIKit
import HUD
import ComponentKit

class FeeSliderWrapper: UIView {
    private let slider = FeeSlider()
    private let decreaseButton = UIButton()
    private let increaseButton = UIButton()

    private let feeRateView = FeeSliderValueView()
    private var sliderLastValue: Float?
    private var step: Int = 1
    var scale: FeePriceScale = FeePriceScale.gwei

    var finishTracking: ((Float) -> ())?

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

        finishTracking?(slider.value)
    }

    @objc private func increase() {
        guard Int(slider.value) < Int(slider.maximumValue) else {
            return
        }
        slider.value = min(slider.value + Float(step), slider.maximumValue)

        finishTracking?(slider.value)
    }

    func set(value: Float, range: ClosedRange<Float>, step: Int, description: String?) {
        slider.minimumValue = range.lowerBound
        slider.maximumValue = range.upperBound
        slider.value = value
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
        feeConfig.exactSize = false
        feeConfig.preferredSize = CGSize(width: hudWidth, height: 48)
        feeConfig.cornerRadius = .cornerRadius8
        feeConfig.handleKeyboard = .none
        feeConfig.inAnimationDuration = 0
        feeConfig.outAnimationDuration = 0

        let convertedPoint = convert(CGPoint(x: 0, y: -feeConfig.preferredSize.height - CGFloat.margin2x), to: nil)
        feeConfig.hudInset = CGPoint(x: position.x - center.x, y: convertedPoint.y)

        return feeConfig
    }

    private func onTracking(_ value: Float, position: CGPoint) {
        HUD.instance.config = hudConfig(position: position)

        let roundedValue = scale.wrap(value: value, step: step)
        let displayValue = scale.description(value: roundedValue, showSymbol: false)

        feeRateView.set(value: displayValue)
        HUD.instance.showHUD(feeRateView)
    }

    private func onFinishTracking(_ value: Float) {
        HUD.instance.hide()

        guard sliderLastValue != value else {
            return
        }
        sliderLastValue = value

        finishTracking?(value)
    }

}
