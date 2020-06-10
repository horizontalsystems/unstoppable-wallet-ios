import UIKit
import SnapKit
import ThemeKit

class SendConfirmationReceiverCell: ThemeCell {
    private static let addressButtonStyle: ThemeButtonStyle = .secondaryDefault
    private static let horizontalPadding: CGFloat = .margin4x
    private static let verticalPadding: CGFloat = .margin2x

    private let addressButton = ThemeButton()

    private var _onHashTap: (() -> ())?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.backgroundColor = .themeLawrence
        backgroundColor = .clear
        selectionStyle = .none

        addSubview(addressButton)
        addressButton.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(SendConfirmationReceiverCell.verticalPadding)
            maker.leading.greaterThanOrEqualToSuperview().offset(SendConfirmationReceiverCell.horizontalPadding)
            maker.trailing.equalToSuperview().inset(SendConfirmationReceiverCell.horizontalPadding)
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

}

extension SendConfirmationReceiverCell {

    static func height(forContainerWidth containerWidth: CGFloat, text: String) -> CGFloat {
        ThemeButton.size(containerWidth: containerWidth - 2 * horizontalPadding, text: text, style: addressButtonStyle).height + 2 * verticalPadding
    }

}
