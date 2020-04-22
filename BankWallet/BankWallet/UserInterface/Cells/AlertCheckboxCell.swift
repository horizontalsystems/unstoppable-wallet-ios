import UIKit
import ThemeKit

class AlertCheckboxCell: UITableViewCell {
    private let checkBoxImageView = UIImageView()
    private let descriptionLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(checkBoxImageView)
        checkBoxImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x)
        }

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(checkBoxImageView.snp.trailing).offset(CGFloat.margin4x)
            maker.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .caption
        descriptionLabel.textColor = .themeOz
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(text: String?, checked: Bool) {
        descriptionLabel.text = text
        checkBoxImageView.image = UIImage(named: checked ? "Checkbox Checked" : "Checkbox Unchecked")
    }

}
