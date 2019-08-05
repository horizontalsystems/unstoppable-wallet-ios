import UIKit

class SendFeeView: UIView {
    private let feePrefix = "send.fee".localized + " "

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

        self.snp.makeConstraints { maker in
            maker.height.equalTo(feeAdjustable ? SendTheme.adjustableFeeHeight : SendTheme.feeHeight)
        }

        backgroundColor = .clear

        addSubview(feeLabel)
        addSubview(errorLabel)
        addSubview(convertedFeeLabel)

        feeLabel.font = SendTheme.feeFont
        feeLabel.textColor = SendTheme.feeColor
        feeLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.feeTitleTopMargin)
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
            maker.top.equalToSuperview().offset(feeAdjustable ? SendTheme.adjustableFeeErrorTopMargin : SendTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
        }

        if feeAdjustable {
            addSubview(feeSlider)

            feeSlider.addTarget(self, action: #selector(sliderShift), for: .valueChanged)
            feeSlider.addTarget(self, action: #selector(onFinishSliding), for: [.touchUpOutside, .touchUpInside])
            feeSlider.snp.makeConstraints { maker in
                maker.leading.equalToSuperview().offset(SendTheme.feeSliderLeftMargin)
                maker.top.equalTo(self.feeLabel.snp.bottom).offset(SendTheme.feeSliderTopMargin)
                maker.trailing.equalToSuperview().offset(-SendTheme.feeSliderRightMargin)
                maker.height.equalTo(SendTheme.feeSliderHeight)
            }
            feeSlider.isHidden = !feeAdjustable
        }
        feeLabel.text = feePrefix

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

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        delegate.viewDidLoad()
    }

}

extension SendFeeView: ISendFeeView {

    func set(fee: String?) {
        guard let fee = fee else {
            feeLabel.text = nil
            return
        }
        feeLabel.text = feePrefix + fee
    }

    func set(convertedFee: String?) {
        convertedFeeLabel.text = convertedFee
    }

    func set(error: String?) {
        errorLabel.text = error

        let hide = error != nil

        feeLabel.isHidden = hide
        convertedFeeLabel.isHidden = hide

        feeSlider.isHidden = !feeAdjustable || hide
    }

}
