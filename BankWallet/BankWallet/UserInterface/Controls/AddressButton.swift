import UIKit

class AddressButton: UIView {
    private let wrapperView = RespondButton()
    private let valueLabel = UILabel()

    var onTap: (() -> ())?

    init() {
        super.init(frame: .zero)

        wrapperView.onTap = { [weak self] in
            self?.onTap?()
        }
        wrapperView.titleLabel.removeFromSuperview()
        wrapperView.backgrounds = [RespondButton.State.active: AddressButtonTheme.background, RespondButton.State.selected: AddressButtonTheme.backgroundSelected]
        wrapperView.borderColor = AddressButtonTheme.borderColor
        wrapperView.borderWidth = 1 / UIScreen.main.scale
        wrapperView.cornerRadius = AddressButtonTheme.cornerRadius
        addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
            maker.height.equalTo(AddressButtonTheme.height)
        }

        let avatarImageView = UIImageView(image: UIImage(named: "Transaction Info Avatar Placeholder")?.tinted(with: AddressButtonTheme.iconColor))
        avatarImageView.setContentHuggingPriority(.required, for: .horizontal)
        wrapperView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(AddressButtonTheme.sideMargin)
            maker.centerY.equalToSuperview()
        }

        valueLabel.font = AddressButtonTheme.valueFont
        valueLabel.textColor = AddressButtonTheme.valueColor
        valueLabel.lineBreakMode = .byTruncatingMiddle
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        wrapperView.addSubview(valueLabel)
        valueLabel.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(avatarImageView.snp.trailing).offset(AddressButtonTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-AddressButtonTheme.sideMargin)
        }
    }

    func bind(value: String) {
        valueLabel.text = value
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
