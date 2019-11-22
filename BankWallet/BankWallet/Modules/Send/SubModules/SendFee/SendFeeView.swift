import UIKit

class SendFeeView: UIView {
    private let delegate: ISendFeeViewDelegate

    private let feeTitleLabel = UILabel()
    private let feeValueLabel = UILabel()
    private let errorLabel = UILabel()

    public init(delegate: ISendFeeViewDelegate) {
        self.delegate = delegate

        super.init(frame: .zero)

        backgroundColor = .clear

        addSubview(feeTitleLabel)
        addSubview(errorLabel)
        addSubview(feeValueLabel)

        feeTitleLabel.text = "send.fee".localized
        feeTitleLabel.font = SendTheme.feeFont
        feeTitleLabel.textColor = SendTheme.feeColor
        feeTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.bottom.lessThanOrEqualToSuperview()
        }

        feeValueLabel.font = SendTheme.feeFont
        feeValueLabel.textColor = SendTheme.feeColor
        feeValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        feeValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeTitleLabel.snp.centerY)
            maker.leading.equalTo(feeTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.lessThanOrEqualToSuperview()
        }

        errorLabel.numberOfLines = 0
        errorLabel.font = .appCaption
        errorLabel.textColor = SendTheme.errorColor
        errorLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.trailing.equalToSuperview().inset(SendTheme.margin)
            maker.bottom.lessThanOrEqualToSuperview()
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

    func set(loading: Bool) {
        feeValueLabel.text = loading ? "Loading..." : nil
    }

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

    func set(error: Error?) {
        errorLabel.text = error?.localizedDescription

        let hide = error != nil

        feeTitleLabel.isHidden = hide
        feeValueLabel.isHidden = hide
    }

}
