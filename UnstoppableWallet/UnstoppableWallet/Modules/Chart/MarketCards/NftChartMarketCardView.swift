import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class NftChartMarketCardView: ChartMarketCardView {
    override class func viewHeight() -> CGFloat {
        ChartMarketCardView.viewHeight() + .margin8 + .heightOneDp + .margin4 + ceil(UIFont.micro.lineHeight) + .margin12
    }

    private let currencyLabel = UILabel()

    required init() {
        super.init()

        commonInit()
    }

    required init(configuration: ChartConfiguration?) {
        super.init(configuration: configuration)

        commonInit()
    }

    private func commonInit() {
        let separatorView = UIView()
        separatorView.snp.makeConstraints { maker in
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        stackView.insertArrangedSubview(separatorView, at: 1)
        stackView.insertArrangedSubview(currencyLabel, at: 3)

        stackView.setCustomSpacing(.margin12 + .margin8, after: currencyLabel)
        stackView.setCustomSpacing(.margin4, after: stackView.arrangedSubviews[2])

        currencyLabel.font = .micro
        currencyLabel.textColor = .themeGray

        separatorView.backgroundColor = .themeSteel20
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func set(viewItem: MarketCardView.ViewItem) {
        super.set(viewItem: viewItem)

        guard let viewItem = viewItem as? ViewItem else {
            currencyLabel.isHidden = true
            return
        }

        currencyLabel.isHidden = viewItem.additionalValue == nil
        currencyLabel.text = viewItem.additionalValue
    }

}


extension NftChartMarketCardView {

    class ViewItem: ChartMarketCardView.ViewItem {
        let additionalValue: String?

        init(title: String?, value: String?, additionalValue: String?, diff: String?, diffColor: UIColor?, data: ChartData?, trend: MovementTrend) {
            self.additionalValue = additionalValue

            super.init(title: title, value: value, diff: diff, diffColor: diffColor, data: data, trend: trend)
        }

    }

}
