import UIKit
import SnapKit

class HashView: RespondButton {
    private let avatarImageView = UIImageView()
    private let valueLabel = UILabel()

    init() {
        super.init()

        let wrapperView = UIView()
        wrapperView.backgroundColor = .clear
        wrapperView.isUserInteractionEnabled = false
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.height.equalTo(HashViewTheme.height)
        }

        titleLabel.removeFromSuperview()
        wrapperView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(TransactionInfoDescriptionTheme.horizontalMargin)
            maker.centerY.equalToSuperview()
        }

        valueLabel.lineBreakMode = .byTruncatingMiddle
        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalTo(self.avatarImageView.snp.trailing).offset(TransactionInfoDescriptionTheme.horizontalMargin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoDescriptionTheme.horizontalMargin)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(value: String?, font: UIFont = HashViewTheme.font, color: UIColor = HashViewTheme.color, showExtra: ShowExtra = .none, onTap: (() -> ())? = nil) {
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
        valueLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        valueLabel.text = value
        valueLabel.font = font
        valueLabel.textColor = color

        let showImage = showExtra == .icon || showExtra == .token || showExtra == .hash
        avatarImageView.isHidden = !showImage
        let image: UIImage?
        switch showExtra {
        case .icon: image = UIImage(named: "Transaction Info Avatar Placeholder")
        case .hash: image = UIImage(named: "Hash Icon")
        default: image = UIImage(named: "Transaction Info Token Placeholder")
        }
        avatarImageView.image = image?.tinted(with: TransactionInfoDescriptionTheme.buttonIconColor)

        avatarImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        avatarImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        avatarImageView.snp.remakeConstraints { maker in
            if !showImage {
                maker.width.equalTo(0)
            } else {
                maker.width.equalTo(image?.size.width ?? 0)
            }
            maker.leadingMargin.equalToSuperview().offset(showImage ? TransactionInfoDescriptionTheme.horizontalMargin : 0)
            maker.centerY.equalToSuperview()
        }
    }

}
