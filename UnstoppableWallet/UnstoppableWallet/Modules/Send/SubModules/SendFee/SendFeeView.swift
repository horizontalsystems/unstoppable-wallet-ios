import UIKit
import EthereumKit

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
        feeTitleLabel.font = .subhead2
        feeTitleLabel.textColor = .themeGray
        feeTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin4x)
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.bottom.lessThanOrEqualToSuperview()
        }

        feeValueLabel.font = .subhead2
        feeValueLabel.textColor = .themeGray
        feeValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        feeValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeTitleLabel.snp.centerY)
            maker.leading.equalTo(feeTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.bottom.lessThanOrEqualToSuperview()
        }

        errorLabel.numberOfLines = 0
        errorLabel.font = .caption
        errorLabel.textColor = .themeLucian
        errorLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin4x)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
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

    func set(error: String?) {
        errorLabel.text = error

        let hide = error != nil

        feeTitleLabel.isHidden = hide
        feeValueLabel.isHidden = hide
    }

}
