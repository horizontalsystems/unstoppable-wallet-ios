import UIKit

class PrivacyHeaderCell: UITableViewCell {
    static var description = "settings_privacy.header_description".localized

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        let descriptionView = NewTopDescriptionView()

        contentView.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        descriptionView.bind(text: PrivacyHeaderCell.description)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func height(containerWidth: CGFloat) -> CGFloat {
        NewTopDescriptionView.height(containerWidth: containerWidth, text: PrivacyHeaderCell.description)
    }

}
