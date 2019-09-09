import UIKit
import SnapKit

class SendConfirmationMemoCell: AppCell {

    private let memoLabel = UILabel()
    private let memoTitleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = SendTheme.holderBackground
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(memoLabel)
        addSubview(memoTitleLabel)

        memoLabel.font = SendTheme.confirmationMemoFont
        memoLabel.textColor = SendTheme.confirmationMemoColor
        memoLabel.textAlignment = .right
        memoLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.confirmationMemoVerticalMargin)
            maker.leading.equalTo(memoTitleLabel.snp.trailing).offset(SendTheme.margin)
        }
        memoTitleLabel.font = SendTheme.confirmationMemoTitleFont
        memoTitleLabel.textColor = SendTheme.confirmationMemoTitleColor
        memoTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.confirmationMemoVerticalMargin)
        }
        memoTitleLabel.text = "send.confirmation.memo_placeholder".localized
        memoTitleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        memoLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(memo: String?, last: Bool = true) {
        super.bind(showDisclosure: false, last: last)
        memoLabel.text = memo
    }

}
