import UIKit
import SnapKit
import UIExtensions
import ThemeKit

class SendFeePriorityView: UIView {
    let delegate: ISendFeePriorityViewDelegate

    private let feeSliderWrapper = FeeSliderWrapper()
    private let separator = UIView()
    private let selectableValueView = C5Cell(style: .default, reuseIdentifier: nil)

    private let customPriorityUnit: CustomPriorityUnit?

    init(delegate: ISendFeePriorityViewDelegate, customPriorityUnit: CustomPriorityUnit?) {
        self.delegate = delegate
        self.customPriorityUnit = customPriorityUnit

        super.init(frame: .zero)

        backgroundColor = .clear

        snp.makeConstraints { maker in
            maker.height.equalTo(57)
        }

        addSubview(feeSliderWrapper)
        feeSliderWrapper.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin3x)
        }
        feeSliderWrapper.finishTracking = { [weak self] value in
            self?.finishTracking(value: value)
        }
        feeSliderWrapper.isHidden = true

        addSubview(separator)
        separator.snp.makeConstraints { maker in
            maker.top.equalTo(feeSliderWrapper.snp.bottom).offset(CGFloat.margin3x)
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightOnePixel)
        }

        separator.backgroundColor = .themeSteel20

        addSubview(selectableValueView.contentView)
        selectableValueView.contentView.snp.makeConstraints { maker in
            maker.top.equalTo(separator.snp.bottom)
            maker.bottom.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        selectableValueView.title = "send.tx_speed".localized
        selectableValueView.titleImage = UIImage(named: "circle_information_20")?.tinted(with: .themeJacob)
        selectableValueView.titleImageAction = { [weak self] in
            self?.openFeeInfo()
        }
        selectableValueView.valueAction = { [weak self] in
            self?.delegate.onFeePrioritySelectorTap()
        }
        selectableValueView.value = delegate.feeRatePriority.title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
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

    private func finishTracking(value: Int) {
        let realRange = convert(feeSliderWrapper.sliderRange, toPresent: false)
        delegate.selectCustom(feeRatePriority: .custom(value: convert(value, toPresent: false), range: realRange))
    }

    private func openFeeInfo() {
        delegate.onOpenFeeInfo()
    }

}

extension SendFeePriorityView: ISendFeePriorityView {

    func setPriority() {
        selectableValueView.value = delegate.feeRatePriority.title
    }

    func set(enabled: Bool) {
        DispatchQueue.main.async {
            self.selectableValueView.valueActionEnabled = enabled
        }
    }

    func set(customVisible: Bool) {
        snp.updateConstraints { maker in
            maker.height.equalTo(customVisible ? 90 : 57)
        }

        feeSliderWrapper.isHidden = !customVisible
    }

    func set(customFeeRateValue: Int, customFeeRateRange: ClosedRange<Int>) {
        let presentationRange = convert(customFeeRateRange)
        feeSliderWrapper.set(value: convert(customFeeRateValue), range: presentationRange, description: customPriorityUnit?.presentationName)
    }

}
