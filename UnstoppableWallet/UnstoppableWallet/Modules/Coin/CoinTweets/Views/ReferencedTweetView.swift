import UIKit
import ComponentKit

class ReferencedTweetView: UIView {
    private static let bodyFont: UIFont = .subhead2

    private let titleView = UILabel()
    private let bodyView = UILabel()

    init() {
        super.init(frame: .zero)

        cornerRadius = .cornerRadius4
        backgroundColor = .themeSteel20

        addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        titleView.font = .caption
        titleView.textColor = .themeGray

        addSubview(bodyView)
        bodyView.snp.makeConstraints { maker in
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
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

        return .margin16 + 12 + .margin12 + textHeight + .margin16
    }

}
