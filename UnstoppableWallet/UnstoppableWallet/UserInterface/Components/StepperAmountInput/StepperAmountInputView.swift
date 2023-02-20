import Foundation
import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import RxSwift
import RxCocoa

class StepperAmountInputView: UIView {
    let disposeBag = DisposeBag()
    let viewHeight: CGFloat = 44

    private let maxValue = Decimal(1_000_000_000)
    private let fractionalsAllowed: Bool
    private let rawFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 9
        formatter.groupingSeparator = ""
        return formatter
    }()

    private var previousValue = Decimal.zero
    private var currentValue = Decimal.zero

    private let inputStackView: InputStackView

    private let minusView = InputSecondaryCircleButtonWrapperView()
    private let plusView = InputSecondaryCircleButtonWrapperView()

    var onChangeValue: ((Decimal) -> ())?

    init(allowFractionalNumbers: Bool) {
        fractionalsAllowed = allowFractionalNumbers

        inputStackView = InputStackView(singleLine: true)
        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(inputStackView)
        inputStackView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        minusView.button.set(image: UIImage(named: "minus_20"))
        minusView.onTapButton = { [weak self] in
            self?.onTapMinus()
        }

        plusView.button.set(image: UIImage(named: "plus_20"))
        plusView.onTapButton = { [weak self] in
            self?.onTapPlus()
        }

        inputStackView.appendSubview(minusView, customSpacing: 16)
        inputStackView.appendSubview(plusView)

        inputStackView.placeholder = ""
        inputStackView.keyboardType = fractionalsAllowed ? .decimalPad : .numberPad
        inputStackView.onChangeText = { [weak self] text in
            self?.set(valueOf: text)
            self?.emitValueIfChanged()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func becomeFirstResponder() -> Bool {
        inputStackView.becomeFirstResponder()
    }

    private func set(valueOf text: String?) {
        previousValue = currentValue
        currentValue = decimalValue(of: text)

        if text != inputStackView.text {
            inputStackView.text = text
        }

        if currentValue >= maxValue || currentValue.exponent < -9 {
            currentValue = previousValue
            inputStackView.text = textValue(previousValue)
        }
    }

    private func emitValueIfChanged() {
        guard currentValue != previousValue else {
            return
        }

        onChangeValue?(currentValue)
    }

    private func decimalValue(of text: String?) -> Decimal {
        guard let text = text, !text.isEmpty,
              let decimal = Decimal(string: text, locale: .current) else {
            return 0
        }

        return decimal
    }

    private func textValue(_ newValue: Decimal?) -> String {
        guard let value = newValue else {
            return ""
        }

        return fractionalsAllowed ? "\(rawFormatter.string(for: value) ?? "")" : "\(NSDecimalNumber(decimal: value).intValue)"
    }

    private func onTapMinus() {
        if currentValue > 0 {
            set(valueOf: textValue(max(currentValue - 1, 0)))
            emitValueIfChanged()
        }
    }

    private func onTapPlus() {
        set(valueOf: textValue(currentValue + 1))
        emitValueIfChanged()
    }

}

extension StepperAmountInputView {

    var value: Decimal? {
        get {
            currentValue
        }
        set {
            set(valueOf: textValue(newValue))
        }
    }

    var textColor: UIColor? {
        get {
            inputStackView.textColor
        }
        set {
            inputStackView.textColor = newValue
        }
    }

    var font: UIFont? {
        get {
            inputStackView.font
        }
        set {
            inputStackView.font = newValue
        }
    }

    var inputColor: UIColor? {
        get {
            inputStackView.textColor
        }
        set {
            inputStackView.textColor = newValue
        }
    }

}

extension StepperAmountInputView: IHeightControlView { // required in FormValidatedView, but not used yet

    var onChangeHeight: (() -> ())? {
        get {
            nil
        }
        set {
        }
    }

    func height(containerWidth: CGFloat) -> CGFloat {
        0
    }

}
