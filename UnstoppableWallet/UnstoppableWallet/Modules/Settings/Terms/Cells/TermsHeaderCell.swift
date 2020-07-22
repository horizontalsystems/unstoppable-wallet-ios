import UIKit
import SnapKit
import ThemeKit

class TermsHeaderCell: UITableViewCell {
    static let height: CGFloat = 104

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        let imageView = UIImageView(image: UIImage(named: "App Icon"))

        contentView.addSubview(imageView)
        imageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalToSuperview().inset(CGFloat.margin6x)
        }

        imageView.setContentHuggingPriority(.required, for: .horizontal)

        let titleLabel = UILabel()

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(imageView.snp.top).inset(10)
            maker.leading.equalTo(imageView.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        titleLabel.text = "Unstoppable"
        titleLabel.font = .headline1
        titleLabel.textColor = .themeOz

        let subtitleLabel = UILabel()

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin2x)
            maker.leading.equalTo(titleLabel.snp.leading)
            maker.trailing.equalTo(titleLabel.snp.trailing)
        }

        subtitleLabel.text = "terms.app_subtitle".localized
        subtitleLabel.font = .subhead2
        subtitleLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
