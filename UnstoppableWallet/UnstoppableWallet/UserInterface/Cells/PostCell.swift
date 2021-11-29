import UIKit
import ComponentKit

class PostCell: BaseSelectableThemeCell {
    static let height: CGFloat = 140

    private let titleFont: UIFont = .headline2

    private let headerLabel = UILabel()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let timeLabel = UILabel()

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(headerLabel)
        headerLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview().inset(CGFloat.margin16)
        }

        headerLabel.numberOfLines = 1
        headerLabel.font = .captionSB
        headerLabel.textColor = .themeGray

        wrapperView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(headerLabel.snp.bottom).offset(CGFloat.margin8)
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

        wrapperView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.margin16)
        }

        timeLabel.font = .micro
        timeLabel.textColor = .themeGray50
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(header: String, title: String, body: String, time: String) {
        headerLabel.text = header
        titleLabel.text = title
        bodyLabel.text = body
        timeLabel.text = time

        let textWidth = UIScreen.main.bounds.width - CGFloat.margin16 * 4

        let titleTextHeight = title.height(forContainerWidth: textWidth, font: titleFont)
        let titleNumberOfLines = Int(titleTextHeight / titleFont.lineHeight)

        if titleNumberOfLines >= 3 {
            bodyLabel.isHidden = true
        } else {
            bodyLabel.isHidden = false
            bodyLabel.numberOfLines = 3 - titleNumberOfLines
        }
    }

}
