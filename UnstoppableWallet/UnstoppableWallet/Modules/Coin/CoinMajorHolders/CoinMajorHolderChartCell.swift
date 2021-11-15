import ComponentKit
import ThemeKit
import SnapKit
import UIKit

class CoinMajorHolderChartCell: UITableViewCell {
    private static let insets = UIEdgeInsets(top: .margin32, left: .margin32, bottom: .margin32, right: .margin32)

    private let donutChartView = DonutChartView()
    private let percentLabel = UILabel()
    private let descriptionLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(donutChartView)
        donutChartView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(Self.insets)
        }

        contentView.addSubview(percentLabel)
        percentLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
        }

        percentLabel.font = .title3
        percentLabel.textColor = .themeJacob

        contentView.addSubview(descriptionLabel)
        descriptionLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(percentLabel.snp.bottom).offset(CGFloat.margin8)
            maker.bottom.equalTo(donutChartView)
            maker.width.equalTo(donutChartView).multipliedBy(0.4)
        }

        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
        descriptionLabel.font = .subhead1
        descriptionLabel.textColor = .themeGray
        descriptionLabel.text = "coin_page.major_holders.chart.description".localized
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(chartPercents: [Double], percent: String) {
        percentLabel.text = percent
        donutChartView.percents = chartPercents
    }

}

extension CoinMajorHolderChartCell {

    static func height(containerWidth: CGFloat) -> CGFloat {
        let donutChartWidth = containerWidth - insets.width
        let donutChartHeight = DonutChartView.height(containerWidth: donutChartWidth)
        return donutChartHeight + insets.height
    }

}
