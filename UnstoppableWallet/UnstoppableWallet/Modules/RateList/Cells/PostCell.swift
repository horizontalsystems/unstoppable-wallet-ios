import UIKit
import ThemeKit

class PostCell: BaseSelectableThemeCell {
    private static let verticalPadding: CGFloat = .margin4x
    private static let horizontalPadding: CGFloat = .margin4x
    private static let subtitleTopMargin: CGFloat = .margin1x
    private static let titleFont: UIFont = .subhead1
    private static let dateFont: UIFont = .micro

    private let titleLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(PostCell.horizontalPadding)
            maker.top.equalToSuperview().inset(PostCell.verticalPadding)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = PostCell.titleFont
        titleLabel.textColor = .themeLeah

        addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(PostCell.horizontalPadding)
            maker.top.equalTo(titleLabel.snp.bottom).offset(PostCell.subtitleTopMargin)
        }

        dateLabel.font = PostCell.dateFont
        dateLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    private func timeAgo(date: Date) -> String {
        // interval from post in minutes
        var interval = Int(Date().timeIntervalSince1970 - date.timeIntervalSince1970) / 60
        if interval < 60 {
            return "timestamp.min_ago".localized(max(1, interval))
        }

        // interval in hours
        interval /= 60
        if interval < 24 {
            return "timestamp.hours_ago".localized(interval)
        }

        // interval in days
        interval /= 24
        return "timestamp.days_ago".localized(interval)
    }

    func bind(viewItem: RateListModule.PostViewItem) {
        titleLabel.text = viewItem.title
        dateLabel.text = timeAgo(date: viewItem.date)
    }

}

extension PostCell {

    static func height(containerWidth: CGFloat, viewItem: RateListModule.PostViewItem) -> CGFloat {
        let titleWidth = containerWidth - 2 * horizontalPadding
        let titleHeight = viewItem.title.height(forContainerWidth: titleWidth, font: titleFont)

        return verticalPadding + titleHeight + subtitleTopMargin + dateFont.lineHeight + verticalPadding
    }

}
