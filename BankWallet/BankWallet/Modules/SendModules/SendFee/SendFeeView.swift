import UIKit

class SendFeeView: UIView {
    private let delegate: ISendFeeViewDelegate
    private let feeAdjustable: Bool

    private let feeLabel = UILabel()
    private let convertedFeeLabel = UILabel()
    private let errorLabel = UILabel()
    private let feeSlider = FeeSlider()

    private var previousValue: Int?

    public init(feeAdjustable: Bool, delegate: ISendFeeViewDelegate) {
        self.feeAdjustable = feeAdjustable
        self.delegate = delegate

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(feeLabel)
        addSubview(errorLabel)
        addSubview(convertedFeeLabel)
        addSubview(feeSlider)

        feeLabel.font = SendTheme.feeFont
        feeLabel.textColor = SendTheme.feeColor
        let feeTitleTopMargin = feeAdjustable ? SendTheme.feeTitleTopMargin : SendTheme.constantFeeTitleTopMargin
        feeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(feeTitleTopMargin)
        }

        convertedFeeLabel.font = SendTheme.feeFont
        convertedFeeLabel.textColor = SendTheme.feeColor
        convertedFeeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        convertedFeeLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.leading.equalTo(feeLabel.snp.trailing).offset(SendTheme.margin)
        }

        errorLabel.numberOfLines = 0
        errorLabel.font = SendTheme.errorFont
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.bottom.equalToSuperview().offset(-SendTheme.smallMargin)
        }

        feeSlider.addTarget(self, action: #selector(sliderShift), for: .valueChanged)
        feeSlider.addTarget(self, action: #selector(onFinishSliding), for: [.touchUpOutside, .touchUpInside])
        feeSlider.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.feeSliderLeftMargin)
            maker.top.equalTo(self.feeLabel.snp.bottom).offset(SendTheme.feeSliderTopMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.feeSliderRightMargin)
            maker.height.equalTo(SendTheme.feeSliderHeight)
        }

        feeLabel.text = "Fee: "
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    @objc private func sliderShift() {
        let a = Int(feeSlider.value * 10)
        let b = Int(feeSlider.value) * 10

        let value = Int(floor(feeSlider.value))
        if previousValue != value, a == b {
            delegate.onFeePriorityChange(value: value)

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()

            previousValue = value
        }
    }

    @objc private func onFinishSliding() {
        UIView.animate(withDuration: 0.2, animations: {
            self.feeSlider.setValue(Float(Int(round(self.feeSlider.value))), animated: true)
        }, completion: { _ in
            self.sliderShift()
        })
    }

    private func set(primaryFeeInfo: AmountInfo?) {
        guard let primaryFeeInfo = primaryFeeInfo else {
            feeLabel.text = nil
            return
        }

        switch primaryFeeInfo {
        case .coinValue(let coinValue):
            feeLabel.text = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            feeLabel.text = ValueFormatter.instance.format(currencyValue: currencyValue, roundingMode: .up)
        }
    }

    private func set(secondaryFeeInfo: AmountInfo?) {
        guard let secondaryFeeInfo = secondaryFeeInfo else {
            convertedFeeLabel.text = nil
            return
        }

        switch secondaryFeeInfo {
        case .coinValue(let coinValue):
            convertedFeeLabel.text = ValueFormatter.instance.format(coinValue: coinValue)
        case .currencyValue(let currencyValue):
            convertedFeeLabel.text = ValueFormatter.instance.format(currencyValue: currencyValue, roundingMode: .up)
        }
    }

    private func set(feeError: FeeError?) {
        guard let error = feeError, case .erc20error(let erc20CoinCode, let fee) = error, let amount = ValueFormatter.instance.format(coinValue: fee) else {
            errorLabel.text = nil

            feeSlider.isHidden = !feeAdjustable
            return
        }

        errorLabel.text = "send_erc.alert".localized(erc20CoinCode, amount)
        feeSlider.isHidden = true
    }

}

extension SendFeeView: ISendFeeView {

    func set(fee: String?) {
        feeLabel.text = fee
    }

    func set(convertedFee: String?) {
        convertedFeeLabel.text = convertedFee
    }

    func set(error: String?) {
        errorLabel.text = error

        feeSlider.isHidden = !feeAdjustable || error != nil
    }

}
