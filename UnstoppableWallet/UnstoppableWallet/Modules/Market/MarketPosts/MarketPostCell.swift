import UIKit
import ComponentKit

class MarketPostCell: BaseSelectableThemeCell {
    static let height: CGFloat = 140

    private let titleFont: UIFont = .headline2

    private let sourceLabel = UILabel()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeAgoLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(sourceLabel)
        sourceLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().inset(CGFloat.margin16)
        }

        sourceLabel.numberOfLines = 1
        sourceLabel.font = .captionSB
        sourceLabel.textColor = .themeGray

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(sourceLabel.snp.bottom).offset(CGFloat.margin8)
        }

        titleLabel.numberOfLines = 3
        titleLabel.font = titleFont
        titleLabel.textColor = .themeLeah

        wrapperView.addSubview(bodyLabel)
        bodyLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin6)
        }

        bodyLabel.font = .subhead2
        bodyLabel.textColor = .themeGray

        wrapperView.addSubview(timeAgoLabel)
        timeAgoLabel.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        timeAgoLabel.font = .micro
        timeAgoLabel.textColor = .themeGray50
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(viewItem: MarketPostViewModel.ViewItem) {
        sourceLabel.text = viewItem.source
        titleLabel.text = viewItem.title
        bodyLabel.text = viewItem.body
        timeAgoLabel.text = viewItem.timeAgo

        let textWidth = UIScreen.main.bounds.width - CGFloat.margin16 * 4

        let titleTextHeight = viewItem.title.height(forContainerWidth: textWidth, font: titleFont)
        let titleNumberOfLines = Int(titleTextHeight / titleFont.lineHeight)

        if titleNumberOfLines >= 3 {
            bodyLabel.isHidden = true
        } else {
            bodyLabel.isHidden = false
            bodyLabel.numberOfLines = 3 - titleNumberOfLines
        }
    }

}
