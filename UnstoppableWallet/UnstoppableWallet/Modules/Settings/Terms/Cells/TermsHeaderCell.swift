import UIKit
import SnapKit
import ThemeKit

class TermsHeaderCell: UITableViewCell {
    static let height: CGFloat = 104

    private let headerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(headerImageView)
        headerImageView.snp.makeConstraints { maker in
            maker.top.equalToSuperview().inset(CGFloat.margin4x)
            maker.leading.equalToSuperview().inset(CGFloat.margin6x)
        }

        headerImageView.setContentHuggingPriority(.required, for: .horizontal)

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(headerImageView.snp.top).inset(10)
            maker.leading.equalTo(headerImageView.snp.trailing).offset(CGFloat.margin4x)
            maker.trailing.equalToSuperview().inset(CGFloat.margin6x)
        }

        titleLabel.font = .headline1
        titleLabel.textColor = .themeOz

        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin2x)
            maker.leading.equalTo(titleLabel.snp.leading)
            maker.trailing.equalTo(titleLabel.snp.trailing)
        }

        subtitleLabel.font = .subhead2
        subtitleLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(image: UIImage? = nil, imageUrl: String? = nil, title: String, subtitle: String?) {
        headerImageView.image = image
        headerImageView.af.cancelImageRequest()

        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            headerImageView.af.setImage(withURL: url)
        }

        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

}
