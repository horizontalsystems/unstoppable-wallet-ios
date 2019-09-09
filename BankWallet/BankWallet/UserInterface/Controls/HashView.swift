import UIKit
import SnapKit

class HashView: RespondButton {
    static private let avatarWidth = UIImage(named: "Transaction Info Avatar Placeholder")?.size.width ?? 0 

    private let avatarImageView = UIImageView()
    private let valueLabel = UILabel()

    init(singleLine: Bool = true) {
        super.init()

        let wrapperView = UIView()
        wrapperView.backgroundColor = .clear
        wrapperView.isUserInteractionEnabled = false
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        titleLabel.removeFromSuperview()
        wrapperView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { maker in
            maker.top.leading.equalToSuperview().offset(TransactionInfoDescriptionTheme.margin)
        }

        if singleLine {
            valueLabel.lineBreakMode = .byTruncatingMiddle
        } else {
            valueLabel.lineBreakMode = .byCharWrapping
            valueLabel.numberOfLines = 3
        }
        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview().offset(TransactionInfoDescriptionTheme.textVerticalMargin)
            maker.bottom.equalToSuperview().offset(-TransactionInfoDescriptionTheme.textVerticalMargin)
            maker.leading.equalTo(self.avatarImageView.snp.trailing).offset(TransactionInfoDescriptionTheme.margin)
            maker.trailing.equalToSuperview().offset(-TransactionInfoDescriptionTheme.margin)
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
            maker.leadingMargin.equalToSuperview().offset(showImage ? TransactionInfoDescriptionTheme.margin : 0)
            maker.top.equalToSuperview().offset(TransactionInfoDescriptionTheme.margin)
        }
    }

    class var textInsets: UIEdgeInsets {
        return UIEdgeInsets(top: TransactionInfoDescriptionTheme.textVerticalMargin, left: 2 * TransactionInfoDescriptionTheme.margin + HashView.avatarWidth, bottom: TransactionInfoDescriptionTheme.textVerticalMargin, right: TransactionInfoDescriptionTheme.margin)
    }

}
