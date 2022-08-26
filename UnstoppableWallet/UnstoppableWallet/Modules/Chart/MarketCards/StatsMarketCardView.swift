import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class StatsMarketCardView: MarketCardView {
    override class func viewHeight() -> CGFloat { MarketCardView.viewHeight() + .margin8 + ChartConfiguration.chartPreview.mainHeight }

    private let titleView = MarketCardTitleView()
    private let valueView = MarketCardValueView()

    required init() {
        super.init()

        commonInit()
    }

    private func commonInit() {
        let topSeparatorView = UIView()
        topSeparatorView.snp.makeConstraints { maker in
            maker.height.equalTo(CGFloat.heightOneDp)
        }
        let bottomSeparatorView = UIView()
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        stackView.insertArrangedSubview(topSeparatorView, at: 1)
        stackView.addArrangedSubview(titleView)
        stackView.addArrangedSubview(bottomSeparatorView)
        stackView.addArrangedSubview(valueView)

        stackView.setCustomSpacing(.margin16, after: stackView.arrangedSubviews[2])

        topSeparatorView.backgroundColor = .themeSteel20
        bottomSeparatorView.backgroundColor = .themeSteel20
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func set(viewItem: MarketCardView.ViewItem) {
        super.set(viewItem: viewItem)

        guard let viewItem = viewItem as? StatsMarketCardView.ViewItem else {
            return
        }

        titleView.title = viewItem.secondaryTitle

        valueView.valueColor = viewItem.secondaryValue == nil ? .themeGray50 : .themeBran
        valueView.value = viewItem.secondaryValue ?? "n/a".localized
    }

}


extension StatsMarketCardView {

    class ViewItem: MarketCardView.ViewItem {
        let secondaryTitle: String?
        let secondaryValue: String?

        init(title: String?, value: String?, diff: String? = nil, diffColor: UIColor? = nil, secondaryTitle: String?, secondaryValue: String?) {
            self.secondaryTitle = secondaryTitle
            self.secondaryValue = secondaryValue

            super.init(title: title, value: value, diff: diff, diffColor: diffColor)
        }

        override var viewType: MarketCardView.Type {
            StatsMarketCardView.self
        }
    }

}
