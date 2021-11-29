import UIKit
import SnapKit
import ThemeKit

class TermsHeaderCell: UITableViewCell {
    static let height: CGFloat = 104

    private let headerImageView = UIImageView()

    private let labelsHolder = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private var subtitleTopMarginConstraint: Constraint?

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(headerImageView)
        headerImageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalToSuperview().inset(CGFloat.margin6x)
            maker.size.equalTo(72)
        }

        headerImageView.setContentHuggingPriority(.required, for: .horizontal)
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.cornerRadius = .margin4x
        headerImageView.clipsToBounds = true
        headerImageView.backgroundColor = .themeElena

        contentView.addSubview(labelsHolder)
        labelsHolder.snp.makeConstraints { maker in
            maker.leading.equalTo(headerImageView.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.centerY.equalTo(headerImageView)
        }

        labelsHolder.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingMiddle
        titleLabel.font = .headline1
        titleLabel.textColor = .themeOz

        labelsHolder.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            subtitleTopMarginConstraint = maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin2x).constraint
            maker.leading.trailing.bottom.equalToSuperview()
        }

        subtitleLabel.font = .subhead2
        subtitleLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(image: UIImage? = nil, imageUrl: String? = nil, title: String, subtitle: String?) {
        headerImageView.kf.setImage(with: imageUrl.flatMap { URL(string: $0) }, placeholder: image, options: [.scaleFactor(UIScreen.main.scale)])

        titleLabel.text = title
        subtitleLabel.text = subtitle

        subtitleTopMarginConstraint?.update(offset: subtitle == nil ? 0 : CGFloat.margin2x)
    }

}
