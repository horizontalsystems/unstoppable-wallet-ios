import UIKit
import ComponentKit

class ReferencedTweetView: UIView {
    private static let titleFont: UIFont = .caption
    private static let bodyFont: UIFont = .subhead2
    private static let sideMargin: CGFloat = .margin16
    private static let insideMargin: CGFloat = .margin12

    private let titleView = UILabel()
    private let bodyView = UILabel()

    init() {
        super.init(frame: .zero)

        cornerRadius = .cornerRadius8
        backgroundColor = .themeSteel10

        addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview().inset(Self.sideMargin)
        }

        titleView.font = .caption
        titleView.textColor = .themeGray

        addSubview(bodyView)
        bodyView.snp.makeConstraints { maker in
            maker.top.equalTo(titleView.snp.bottom).offset(Self.insideMargin)
            maker.bottom.leading.trailing.equalToSuperview().inset(Self.sideMargin)
        }

        bodyView.numberOfLines = 0
        bodyView.font = Self.bodyFont
        bodyView.textColor = .themeLeah
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(tweet: CoinTweetsViewModel.ReferencedTweet) {
        titleView.text = tweet.title
        bodyView.text = tweet.text
    }

    static func height(tweet: CoinTweetsViewModel.ReferencedTweet, containerWidth: CGFloat) -> CGFloat {
        let textHeight = tweet.text.height(forContainerWidth: containerWidth - .margin16 * 2, font: Self.bodyFont)

        return ceil(Self.sideMargin + Self.titleFont.lineHeight + Self.insideMargin + textHeight + Self.sideMargin)
    }

}
