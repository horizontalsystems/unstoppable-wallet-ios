import UIKit

class SendFeeView: UIView {
    private let delegate: ISendFeeViewDelegate

    private let feeTitleLabel = UILabel()
    private let feeValueLabel = UILabel()
    private let durationTitleLabel = UILabel()
    private let durationValueLabel = UILabel()
    private let errorLabel = UILabel()

    public init(delegate: ISendFeeViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)

        self.snp.makeConstraints { maker in
            maker.height.equalTo(SendTheme.feeHeight)
        }

        backgroundColor = .clear

        addSubview(durationTitleLabel)
        addSubview(durationValueLabel)
        addSubview(feeTitleLabel)
        addSubview(errorLabel)
        addSubview(feeValueLabel)

        durationTitleLabel.text = "send.tx_duration".localized
        durationTitleLabel.font = SendTheme.feeFont
        durationTitleLabel.textColor = SendTheme.feeColor
        durationTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.feeTitleTopMargin)
        }

        durationValueLabel.font = SendTheme.feeFont
        durationValueLabel.textColor = SendTheme.feeColor
        durationValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        durationValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(durationTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.leading.equalTo(durationTitleLabel.snp.trailing).offset(SendTheme.margin)
        }

        feeTitleLabel.text = "send.fee".localized
        feeTitleLabel.font = SendTheme.feeFont
        feeTitleLabel.textColor = SendTheme.feeColor
        feeTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(durationTitleLabel.snp.bottom).offset(SendTheme.feeTitleTopMargin)
        }

        feeValueLabel.font = SendTheme.feeFont
        feeValueLabel.textColor = SendTheme.feeColor
        feeValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        feeValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeTitleLabel.snp.centerY)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.leading.equalTo(feeTitleLabel.snp.trailing).offset(SendTheme.margin)
        }

        errorLabel.numberOfLines = 0
        errorLabel.font = .appCaption
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalTo(durationTitleLabel.snp.bottom).offset(SendTheme.smallMargin)
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        delegate.viewDidLoad()
    }

}

extension SendFeeView: ISendFeeView {

    func set(fee: AmountInfo, convertedFee: AmountInfo?) {
        guard let formattedFeeString = fee.formattedString else {
            feeValueLabel.text = nil
            return
        }

        if let formattedConvertedFeeString = convertedFee?.formattedString {
            feeValueLabel.text = "\(formattedFeeString) | \(formattedConvertedFeeString)"
            return
        }

        feeValueLabel.text = "\(formattedFeeString)"
    }

    func set(duration: TimeInterval?) {
        durationValueLabel.text = duration.map { "send.duration.within".localized($0.approximateHoursOrMinutes) } ?? "send.duration.instant".localized
    }

    func set(error: Error?) {
        errorLabel.text = error?.localizedDescription

        let hide = error != nil

        feeTitleLabel.isHidden = hide
        feeValueLabel.isHidden = hide
    }

}
