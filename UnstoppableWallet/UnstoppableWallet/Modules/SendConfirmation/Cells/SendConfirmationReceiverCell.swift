import UIKit
import SnapKit
import ThemeKit

class SendConfirmationReceiverCell: ThemeCell {
    private static let addressButtonStyle = ThemeButtonStyle.secondaryDefault

    private let addressButton = ThemeButton()

    private var _onHashTap: (() -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .themeLawrence
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(addressButton)
        addressButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
            maker.leading.greaterThanOrEqualToSuperview().offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        addressButton.apply(style: SendConfirmationReceiverCell.addressButtonStyle)
        // By default UIButton has no constraints to its titleLabel.
        // In order to support multiline title the following constraints are required
        addressButton.titleLabel?.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(addressButton.contentEdgeInsets)
        }

        addressButton.titleLabel?.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addressButton.titleLabel?.numberOfLines = 0
        addressButton.titleLabel?.textAlignment = .right
        addressButton.addTarget(self, action: #selector(onHashTap), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @objc private func onHashTap() {
        _onHashTap?()
    }

    func bind(receiver: String, last: Bool = false, onHashTap: (() -> ())?) {
        super.bind(showDisclosure: false, last: last)
        _onHashTap = onHashTap

        addressButton.setTitle(receiver, for: .normal)
    }

    static func height(forContainerWidth containerWidth: CGFloat, text: String) -> CGFloat {
        ceil(ThemeButton.height(forContainerWidth: containerWidth - 2 * CGFloat.margin4x, text: text, style: SendConfirmationReceiverCell.addressButtonStyle)) + 2 * .margin2x
    }

}
