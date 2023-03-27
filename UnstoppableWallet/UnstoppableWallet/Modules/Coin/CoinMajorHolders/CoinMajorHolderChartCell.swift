import ComponentKit
import ThemeKit
import SnapKit
import UIKit

class CoinMajorHolderChartCell: BaseThemeCell {
    static let height: CGFloat = 55

    private let percentLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let countLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        wrapperView.addSubview(countLabel)
        countLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalToSuperview()
        }

        countLabel.font = .subhead2
        countLabel.textColor = .themeGray

        wrapperView.addSubview(percentLabel)
        percentLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(countLabel.snp.bottom).offset(CGFloat.margin12)
        }

        percentLabel.font = .headline1
        percentLabel.textColor = .themeBran

        wrapperView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(percentLabel.snp.trailing).offset(CGFloat.margin8)
            maker.lastBaseline.equalTo(percentLabel)
        }

        descriptionLabel.font = .subhead1
        descriptionLabel.textColor = .themeGray
        descriptionLabel.text = "coin_analytics.holders.in_top_10_addresses".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(percent: String?, count: String?) {
        percentLabel.text = percent
        countLabel.text = count.map { "coin_analytics.holders.count".localized($0) }
    }

}
