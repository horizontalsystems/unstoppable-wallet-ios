import UIKit
import SnapKit

class TransactionInfoDescriptionView: RespondButton {
    private static let iconImage =  UIImage(named: "Transaction Info Avatar Placeholder")
    private static let hashImage =  UIImage(named: "Transaction Info Hash Placeholder")
    let avatarImageView = UIImageView(image: nil)
    let wrapperView = RespondButton()
    let valueLabel = UILabel()

    init() {
        super.init()

        titleLabel.removeFromSuperview()
        addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoDescriptionTheme.middleMargin)
            maker.centerY.equalToSuperview()
        }

        valueLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(self.avatarImageView.snp.trailing).offset(TransactionInfoDescriptionTheme.middleMargin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoDescriptionTheme.middleMargin)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(value: String?, font: UIFont, color: UIColor, showExtra: ShowExtra = .none, onTap: (() -> ())? = nil) {
        if let onTap = onTap {
            self.onTap = onTap
            backgrounds = [RespondButton.State.active: TransactionInfoDescriptionTheme.buttonBackground, RespondButton.State.selected: TransactionInfoDescriptionTheme.buttonBackgroundSelected]
            borderColor = TransactionInfoDescriptionTheme.buttonBorderColor
            borderWidth = 1 / UIScreen.main.scale
            cornerRadius = TransactionInfoDescriptionTheme.buttonCornerRadius
        } else {
            backgrounds = [RespondButton.State.active: .clear, RespondButton.State.selected: .clear]
            borderColor = .clear
            borderWidth = 0
            cornerRadius = 0
        }

        valueLabel.text = value
        valueLabel.font = font
        valueLabel.textColor = color

        avatarImageView.set(hidden: showExtra == .none)
        var image: UIImage?
        switch showExtra {
        case .hash: image = TransactionInfoDescriptionView.hashImage
        default: image = TransactionInfoDescriptionView.iconImage
        }
        avatarImageView.image = image?.tinted(with: TransactionInfoDescriptionTheme.buttonIconColor)
        avatarImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        avatarImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        valueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let showImage = showExtra != .none
        avatarImageView.snp.remakeConstraints { maker in
            if !showImage {
                maker.width.equalTo(0)
            }
            maker.top.equalToSuperview().offset(TransactionInfoDescriptionTheme.verticalMargin)
            maker.bottom.equalToSuperview().offset(-TransactionInfoDescriptionTheme.verticalMargin)
            maker.leadingMargin.equalToSuperview().offset(showImage ? TransactionInfoDescriptionTheme.middleMargin : 0)
            maker.centerY.equalToSuperview()
        }
    }

}
