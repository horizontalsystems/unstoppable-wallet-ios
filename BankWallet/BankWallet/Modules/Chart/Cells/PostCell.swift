import UIKit
import ThemeKit

class PostCell: ThemeCell {
    private static let titleFont = UIFont.subhead1
    private static let subtitleFont = UIFont.micro

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .themeLawrence
        contentView.backgroundColor = .clear

        addSubview(titleLabel)
        addSubview(subtitleLabel)

        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview().inset(CGFloat.margin4x)
        }
        titleLabel.textColor = .themeLeah
        titleLabel.font = PostCell.titleFont
        titleLabel.numberOfLines = 0

        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin1x)
        }
        subtitleLabel.textColor = .themeGray
        subtitleLabel.font = PostCell.subtitleFont
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(title: String?, subtitle: String?) {
        super.bind()

        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

}

extension PostCell {

    static func height(forContainerWidth containerWidth: CGFloat, title: String, subtitle: String) -> CGFloat {
        title.height(forContainerWidth: containerWidth - 2 * CGFloat.margin4x, font: PostCell.titleFont) + PostCell.subtitleFont.lineHeight + CGFloat.margin1x + 2 * CGFloat.margin4x
    }

}
