import UIKit

class SendFeeCell: UITableViewCell {
    private let feeLabel = UILabel()
    private let convertedFeeLabel = UILabel()
    private let errorLabel = UILabel()
    private let feeSlider = FeeSlider()

    private var previousValue: Int?

    private var item: SFeeItem?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(feeLabel)
        addSubview(errorLabel)
        addSubview(convertedFeeLabel)
        addSubview(feeSlider)

        feeLabel.font = SendTheme.feeFont
        feeLabel.textColor = SendTheme.feeColor

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

        sliderShift(disableSend: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(item: SFeeItem) {
        self.item = item
        item.bind = { [weak self] in
            self?.bind()
        }

        feeSlider.isHidden = !item.isFeeAdjustable

        let feeTitleTopMargin = item.isFeeAdjustable ? SendTheme.feeTitleTopMargin : SendTheme.constantFeeTitleTopMargin
        feeLabel.snp.remakeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(feeTitleTopMargin)
        }

        bind()
    }

    @objc private func sliderShift(disableSend: Bool = false) {
        let a = Int(feeSlider.value * 10)
        let b = Int(feeSlider.value) * 10

        let value = Int(floor(feeSlider.value))
        if previousValue != value, !disableSend, a == b {
            item?.delegate?.onFeePriorityChange(value: value)

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

            feeSlider.isHidden = !(item?.isFeeAdjustable ?? true)
            return
        }

        errorLabel.text = "send_erc.alert".localized(erc20CoinCode, amount)
        feeSlider.isHidden = true
    }

    private func bind() {
        guard let feeItem = item else {
            set(primaryFeeInfo: nil)
            set(secondaryFeeInfo: nil)
            set(feeError: nil)

            return
        }

        if let error = feeItem.feeInfo?.error {
            set(primaryFeeInfo: nil)
            set(secondaryFeeInfo: nil)

            set(feeError: error)
        } else {
            set(feeError: nil)

            set(primaryFeeInfo: feeItem.feeInfo?.primaryFeeInfo)
            set(secondaryFeeInfo: feeItem.feeInfo?.secondaryFeeInfo)
        }
    }

}
