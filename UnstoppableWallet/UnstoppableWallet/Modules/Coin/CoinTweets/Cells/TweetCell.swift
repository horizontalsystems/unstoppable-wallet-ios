import UIKit
import ComponentKit

class TweetCell: BaseSelectableThemeCell {
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subTitleLabel = UILabel()
    private let titleImage = UIImageView()

    private let textView = MarkdownTextView()

    private let referencedTweetView = UIView()
    private let referencedTweetTitleView = UILabel()
    private let referencedTweetBodyView = UILabel()

    private let dateLabel = UILabel()

    private static let bodyFont: UIFont = .subhead2

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        headerView.addSubview(titleImage)
        titleImage.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.width.equalTo(CGFloat.iconSize24)
        }

        titleImage.cornerRadius = 12

        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.equalTo(titleImage.snp.trailing).offset(CGFloat.margin8)
        }

        titleLabel.font = .body
        titleLabel.textColor = .themeOz

        headerView.addSubview(subTitleLabel)
        subTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin2)
            maker.leading.equalTo(titleLabel.snp.leading)
            maker.bottom.equalToSuperview()
        }

        subTitleLabel.font = .caption
        subTitleLabel.textColor = .themeGray

        wrapperView.addSubview(headerView)
        headerView.snp.makeConstraints { maker in
            maker.leading.trailing.top.equalToSuperview().inset(CGFloat.margin16)
        }

        wrapperView.addSubview(textView)
        textView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(headerView.snp.bottom).offset(CGFloat.margin12)
        }

        referencedTweetView.addSubview(referencedTweetTitleView)
        referencedTweetTitleView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        referencedTweetTitleView.font = .caption
        referencedTweetTitleView.textColor = .themeGray

        referencedTweetView.addSubview(referencedTweetBodyView)
        referencedTweetBodyView.snp.makeConstraints { maker in
            maker.top.equalTo(referencedTweetTitleView.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        referencedTweetBodyView.numberOfLines = 0
        referencedTweetBodyView.font = Self.bodyFont
        referencedTweetBodyView.textColor = .themeLeah

        wrapperView.addSubview(referencedTweetView)
        referencedTweetView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(textView.snp.bottom).offset(CGFloat.margin12)
        }

        referencedTweetView.cornerRadius = .cornerRadius4
        referencedTweetView.backgroundColor = .themeSteel20

        wrapperView.addSubview(dateLabel)

        dateLabel.font = .micro
        dateLabel.textColor = .themeGray50
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: CoinTweetsViewModel.ViewItem) {
        titleImage.af.cancelImageRequest()
        if let url = URL(string: viewItem.titleImageUrl) {
            titleImage.af.setImage(withURL: url)
        }

        titleLabel.text = viewItem.title
        subTitleLabel.text = viewItem.subTitle

        let attributedString = NSMutableAttributedString(string: viewItem.text, attributes: [
            .foregroundColor: UIColor.themeLeah,
            .font: Self.bodyFont
        ])
        
        for entity in TwitterText.entities(in: viewItem.text) {
            switch entity.type {
                case .url, .hashtag, .screenName, .listname: attributedString.addAttribute(.foregroundColor, value: UIColor.themeIssykBlue, range: entity.range)
            default: ()
            }
        }

        textView.attributedText = attributedString

        if let referencedTweet = viewItem.referencedTweet {
            referencedTweetView.isHidden = false
            referencedTweetTitleView.text = referencedTweet.title
            referencedTweetBodyView.text = referencedTweet.text

            dateLabel.snp.remakeConstraints { maker in
                maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin16)
                maker.top.equalTo(referencedTweetView.snp.bottom).offset(CGFloat.margin12)
            }
        } else {
            referencedTweetView.isHidden = true
            dateLabel.snp.remakeConstraints { maker in
                maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin16)
                maker.top.equalTo(textView.snp.bottom).offset(CGFloat.margin12)
            }
        }

        dateLabel.text = viewItem.date
    }

    static func height(viewItem: CoinTweetsViewModel.ViewItem, containerWidth: CGFloat) -> CGFloat {
        let textWidth: CGFloat = containerWidth - .margin16 * 4
        let textHeight = viewItem.text.height(forContainerWidth: textWidth, font: bodyFont)
        let mainHeight: CGFloat = .margin16 + 37 + .margin12 + textHeight + .margin12 + 12 + .margin16 + .margin12

        if let referencedTweet = viewItem.referencedTweet {
            let rTextHeight = referencedTweet.text.height(forContainerWidth: textWidth - .margin16 * 2, font: bodyFont)

            return mainHeight + .margin16 + 12 + 12 + rTextHeight + .margin16
        }

        return mainHeight
    }

}
