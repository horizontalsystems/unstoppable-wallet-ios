import UIKit

class SendEthereumFeeCell: UITableViewCell {
    private let feeTitleLabel = UILabel()
    private let feeValueLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        addSubview(feeTitleLabel)
        feeTitleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        feeTitleLabel.text = "send.fee".localized
        feeTitleLabel.font = .subhead2
        feeTitleLabel.textColor = .themeGray

        addSubview(feeValueLabel)
        feeValueLabel.snp.makeConstraints { maker in
            maker.centerY.equalTo(feeTitleLabel.snp.centerY)
            maker.leading.equalTo(feeTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        feeValueLabel.font = .subhead2
        feeValueLabel.textColor = .themeGray
        feeValueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(value: String?) {
        feeValueLabel.text = value
    }

}
