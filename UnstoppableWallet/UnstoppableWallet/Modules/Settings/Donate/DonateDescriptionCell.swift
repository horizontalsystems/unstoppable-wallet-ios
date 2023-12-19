import ComponentKit
import UIKit

class DonateDescriptionCell: UITableViewCell {
    private static let horizontalPadding: CGFloat = .margin32
    private static let verticalPadding: CGFloat = .margin24
    private static let labelFont: UIFont = .headline2
    private static let descriptionLabelFont: UIFont = .subhead2

    let label = UILabel()
    let emoji = UIImageView()
    let getAddressButton = PrimaryButton()
    let descriptionLabel = UILabel()

    var onGetAddressAction: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(label)
        label.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(DonateDescriptionCell.horizontalPadding)
            maker.top.equalToSuperview().inset(DonateDescriptionCell.verticalPadding)
        }

        label.numberOfLines = 0
        label.font = DonateDescriptionCell.labelFont
        label.textColor = .themeLeah
        label.textAlignment = .center

        contentView.addSubview(emoji)
        emoji.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(label.snp.bottom).offset(DonateDescriptionCell.verticalPadding)
        }

        emoji.image = UIImage(named: "heart_fill_24")?.withTintColor(.themeJacob)

        contentView.addSubview(getAddressButton)
        getAddressButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(emoji.snp.bottom).offset(DonateDescriptionCell.verticalPadding)
        }

        getAddressButton.set(style: .gray)
        getAddressButton.setTitle("donate.list.get_address".localized, for: .normal)
        getAddressButton.addTarget(self, action: #selector(onGetAddress), for: .touchUpInside)

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(DonateDescriptionCell.horizontalPadding)
            maker.top.equalTo(getAddressButton.snp.bottom).offset(DonateDescriptionCell.verticalPadding)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = DonateDescriptionCell.descriptionLabelFont
        descriptionLabel.textColor = .themeGray
        descriptionLabel.textAlignment = .center
        descriptionLabel.text = "donate.support.bottom_description".localized
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onGetAddress() {
        onGetAddressAction?()
    }
}

extension DonateDescriptionCell {
    static func height(containerWidth: CGFloat, text: String, font: UIFont? = nil, ignoreBottomMargin: Bool = false) -> CGFloat {
        let textHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font ?? Self.labelFont)
        let descriptionTextHeight = text.height(forContainerWidth: containerWidth - 2 * horizontalPadding, font: font ?? Self.descriptionLabelFont)
        return textHeight + .margin24 + .margin24 + .heightButton + +.margin24 + descriptionTextHeight + (ignoreBottomMargin ? 1 : 2) * verticalPadding
    }
}
