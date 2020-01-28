import UIKit
import SnapKit

class HashView: RespondButton {
    private static let avatarWidth = UIImage(named: "Transaction Info Avatar Placeholder")?.size.width ?? 0
    private static let textVerticalMargin: CGFloat = 6

    private let avatarImageView = UIImageView()
    private let valueLabel = UILabel()

    init(singleLine: Bool = true) {
        super.init()

        let wrapperView = UIView()
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        wrapperView.backgroundColor = .clear
        wrapperView.isUserInteractionEnabled = false

        titleLabel.removeFromSuperview()

        wrapperView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { maker in
            maker.top.leading.equalToSuperview().offset(CGFloat.margin2x)
        }

        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview().inset(HashView.textVerticalMargin)
            maker.leading.equalTo(self.avatarImageView.snp.trailing).offset(CGFloat.margin2x)
            maker.trailing.equalToSuperview().offset(-CGFloat.margin2x)
        }

        if singleLine {
            valueLabel.lineBreakMode = .byTruncatingMiddle
        } else {
            valueLabel.lineBreakMode = .byCharWrapping
            valueLabel.numberOfLines = 3
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(value: String?, font: UIFont = .subhead1, color: UIColor = .themeOz, showExtra: ShowExtra = .none, onTap: (() -> ())? = nil) {
        if let onTap = onTap {
            self.onTap = onTap
            backgrounds = [RespondButton.State.active: .themeJeremy, RespondButton.State.selected: .themeJeremy]
            borderColor = .themeSteel20
            borderWidth = 1 / UIScreen.main.scale
            cornerRadius = .cornerRadius1x
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
        avatarImageView.image = image?.tinted(with: .themeGray)

        avatarImageView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        avatarImageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        avatarImageView.snp.remakeConstraints { maker in
            if !showImage {
                maker.width.equalTo(0)
            } else {
                maker.width.equalTo(image?.size.width ?? 0)
            }
            maker.leadingMargin.equalToSuperview().offset(showImage ? CGFloat.margin2x : 0)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
        }
    }

    class var textInsets: UIEdgeInsets {
        UIEdgeInsets(top: HashView.textVerticalMargin, left: 2 * CGFloat.margin2x + HashView.avatarWidth, bottom: HashView.textVerticalMargin, right: CGFloat.margin2x)
    }

}
