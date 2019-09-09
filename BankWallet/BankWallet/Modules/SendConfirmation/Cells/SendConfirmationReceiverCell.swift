import UIKit
import SnapKit

class SendConfirmationReceiverCell: AppCell {
    private let hashView = HashView(singleLine: false)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = SendTheme.holderBackground
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(hashView)

        hashView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(SendTheme.margin)
            maker.top.equalToSuperview().offset(SendTheme.confirmationReceiverTopMargin)
            maker.trailing.lessThanOrEqualToSuperview().offset(-SendTheme.margin)
        }
        hashView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        hashView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(receiver: String, last: Bool = false, onHashTap: (() -> ())?) {
        super.bind(showDisclosure: false, last: last)
        hashView.bind(value: receiver, showExtra: .icon, onTap: onHashTap)
    }

    static func height(forContainerWidth containerWidth: CGFloat, text: String) -> CGFloat {
        let insets = HashView.textInsets
        return ceil(text.height(forContainerWidth: containerWidth - 2 * SendTheme.margin - insets.width, font: HashViewTheme.font)) + insets.height + 2 * SendTheme.confirmationReceiverTopMargin
    }

}
