import UIKit
import ComponentKit

class MarketPostCell: BaseSelectableThemeCell {
    static let height: CGFloat = 158

    private let sourceLabel = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let dateLabel = UILabel()

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

        titleLabel.numberOfLines = 2
        titleLabel.font = .subhead1
        titleLabel.textColor = .themeLeah

        wrapperView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleLabel.snp.bottom).offset(CGFloat.margin8)
        }

        descriptionLabel.numberOfLines = 3
        descriptionLabel.font = .caption
        descriptionLabel.textColor = .themeGray

        wrapperView.addSubview(dateLabel)
        dateLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(descriptionLabel.snp.bottom).offset(CGFloat.margin8)
        }

        dateLabel.font = .micro
        dateLabel.textColor = .themeGray
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func set(source: String, title: String, description: String, date: String) {
        sourceLabel.text = source
        titleLabel.text = title
        descriptionLabel.text = description
        dateLabel.text = date
    }

}
