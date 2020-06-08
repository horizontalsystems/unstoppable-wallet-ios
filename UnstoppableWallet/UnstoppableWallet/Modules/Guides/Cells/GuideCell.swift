import UIKit
import ThemeKit
import SnapKit
import AlamofireImage

class GuideCell: UITableViewCell {
    private static let cardBottomMargin: CGFloat = .margin3x
    private static let cardHorizontalMargin: CGFloat = .margin4x
    private static let imageHeight: CGFloat = 160
    private static let dateTopMargin: CGFloat = .margin4x
    private static let titleTopMargin: CGFloat = .margin2x
    private static let titleBottomMargin: CGFloat = .margin4x
    private static let titleHorizontalMargin: CGFloat = .margin4x
    private static let dateFont: UIFont = .caption
    private static let titleFont: UIFont = .title3

    private let cardView = CardView(insets: .zero)

    private let guideImageView = UIImageView()
    private let dateLabel = UILabel()
    private let titleLabel = UILabel()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(cardView)
        cardView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(GuideCell.cardHorizontalMargin)
            maker.top.equalToSuperview()
            maker.bottom.equalToSuperview().inset(GuideCell.cardBottomMargin)
        }

        cardView.contentView.addSubview(guideImageView)
        guideImageView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(GuideCell.imageHeight)
        }

        guideImageView.contentMode = .scaleAspectFill
        guideImageView.clipsToBounds = true

        cardView.contentView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(guideImageView.snp.bottom).offset(CGFloat.margin4x)
        }

        dateLabel.font = GuideCell.dateFont
        dateLabel.textColor = .themeGray

        cardView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(GuideCell.titleHorizontalMargin)
            maker.top.equalTo(dateLabel.snp.bottom).offset(GuideCell.titleTopMargin)
        }

        titleLabel.numberOfLines = 0
        titleLabel.font = GuideCell.titleFont
        titleLabel.textColor = .themeOz
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(viewItem: GuideViewItem) {
        guideImageView.image = nil

        if let imageUrl = viewItem.imageUrl, let url = URL(string: imageUrl) {
            guideImageView.af.setImage(withURL: url)
        }

        dateLabel.text = GuideCell.formattedDate(viewItem: viewItem)
        titleLabel.text = viewItem.title
    }

}

extension GuideCell {

    private static func formattedDate(viewItem: GuideViewItem) -> String {
        DateFormatter.cachedFormatter(format: "MMMM d, yyyy").string(from: viewItem.date)
    }

}

extension GuideCell {

    static func height(containerWidth: CGFloat, viewItem: GuideViewItem) -> CGFloat {
        let titleWidth = containerWidth - 2 * cardHorizontalMargin - 2 * titleHorizontalMargin
        let titleHeight = viewItem.title.height(forContainerWidth: titleWidth, font: titleFont)

        return imageHeight + dateTopMargin + dateFont.lineHeight + titleTopMargin + titleHeight + titleBottomMargin + cardBottomMargin
    }

}
