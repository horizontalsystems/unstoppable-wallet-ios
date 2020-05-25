import UIKit
import SnapKit
import ThemeKit

class SendConfirmationMemoCell: ThemeCell {

    private let memoLabel = UILabel()
    private let memoTitleLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.snp.makeConstraints { maker in
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }
        contentView.backgroundColor = .themeLawrence

        addSubview(memoLabel)
        addSubview(memoTitleLabel)

        memoLabel.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalTo(memoTitleLabel.snp.trailing).offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        memoLabel.font = .subhead1I
        memoLabel.textColor = .themeOz
        memoLabel.textAlignment = .right

        memoTitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        memoTitleLabel.font = .subhead1
        memoTitleLabel.textColor = .themeGray
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
