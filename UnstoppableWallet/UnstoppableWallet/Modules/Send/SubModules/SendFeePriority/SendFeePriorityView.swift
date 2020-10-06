import UIKit
import SnapKit
import UIExtensions
import HUD

class SendFeePriorityView: UIView {
    let delegate: ISendFeePriorityViewDelegate

    private let durationTitleLabel = UILabel()
    private let durationValueLabel = UILabel()

    private let feeSliderWrapper = FeeSliderWrapper()
    private let selectableValueView = SelectableValueView(title: "send.tx_speed".localized)
    private let feeRateView = FeeSliderValueView()

    private let customPriorityUnit: CustomPriorityUnit?

    init(delegate: ISendFeePriorityViewDelegate, customPriorityUnit: CustomPriorityUnit?) {
        self.delegate = delegate
        self.customPriorityUnit = customPriorityUnit

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(durationTitleLabel)
        durationTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }
        durationTitleLabel.text = "send.tx_duration".localized
        durationTitleLabel.font = .subhead2
        durationTitleLabel.textColor = .themeGray

        addSubview(durationValueLabel)
        durationValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(durationTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalTo(durationTitleLabel.snp.trailing).offset(CGFloat.margin4x)
        }
        durationValueLabel.font = .subhead2
        durationValueLabel.textColor = .themeGray
        durationValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addSubview(feeSliderWrapper)
        feeSliderWrapper.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
        feeSliderWrapper.onTracking = { [weak self] value, position in
            self?.onTracking(value, position: position)
        }
        feeSliderWrapper.finishTracking = { [weak self] value in
            self?.finishTracking(value: value)
        }
        feeSliderWrapper.isHidden = true

        addSubview(selectableValueView)
        selectableValueView.snp.makeConstraints { maker in
            maker.top.equalTo(durationTitleLabel.snp.bottom).offset(CGFloat.margin3x)
            maker.top.equalTo(feeSliderWrapper.snp.bottom)
            maker.bottom.leading.trailing.equalToSuperview()
        }
        selectableValueView.delegate = self
        selectableValueView.set(value: delegate.feeRatePriority.title)

        feeRateView.set(descriptionText: customPriorityUnit?.presentationName)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    private func hudConfig(position: CGPoint) -> HUDConfig {
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
        feeConfig.preferredSize = CGSize(width: 74, height: 48)
        feeConfig.cornerRadius = CGFloat.cornerRadius2x
        feeConfig.handleKeyboard = .none
        feeConfig.inAnimationDuration = 0
        feeConfig.outAnimationDuration = 0

        feeConfig.hudInset = convert(CGPoint(x: position.x - center.x, y: -feeConfig.preferredSize.height - CGFloat.margin2x), to: nil)
        return feeConfig
    }

    private func convert(_ value: Int, toPresent: Bool = true) -> Int {
        let decimals = customPriorityUnit?.presentationDecimals ?? 0
        var multi = pow(10, decimals)
        multi = toPresent ? 1 / multi : multi
        return NSDecimalNumber(decimal: Decimal(value) * multi).intValue
    }

    private func convert(_ range: ClosedRange<Int>, toPresent: Bool = true) -> ClosedRange<Int> {
        convert(range.lowerBound, toPresent: toPresent)...convert(range.upperBound, toPresent: toPresent)
    }

    private func onTracking(_ value: Int, position: CGPoint) {
        HUD.instance.config = hudConfig(position: position)

        feeRateView.set(value: "\(value)")
        HUD.instance.showHUD(feeRateView)
    }

    private func finishTracking(value: Int) {
        HUD.instance.hide()

        let realRange = convert(feeSliderWrapper.sliderRange, toPresent: false)
        delegate.selectCustom(feeRatePriority: .custom(value: convert(value, toPresent: false), range: realRange))
    }

}

extension SendFeePriorityView: ISendFeePriorityView {

    func setPriority() {
        selectableValueView.set(value: delegate.feeRatePriority.title)
    }

    func set(enabled: Bool) {
        DispatchQueue.main.async {
            self.selectableValueView.set(enabled: enabled)
        }
    }

    func set(customVisible: Bool) {
        feeSliderWrapper.isHidden = !customVisible
        durationTitleLabel.isHidden = customVisible
        durationValueLabel.isHidden = customVisible
    }

    func set(customFeeRateValue: Int, customFeeRateRange: ClosedRange<Int>) {
        let presentationRange = convert(customFeeRateRange)
        feeSliderWrapper.set(value: convert(customFeeRateValue), range: presentationRange)
    }

    func set(duration: TimeInterval?) {
        durationValueLabel.text = duration.map { "send.duration.within".localized($0.approximateHoursOrMinutes) } ?? "send.duration.instant".localized
    }

}

extension SendFeePriorityView: ISelectableValueViewDelegate {

    func onSelectorTap() {
        self.delegate.onFeePrioritySelectorTap()
    }

}
