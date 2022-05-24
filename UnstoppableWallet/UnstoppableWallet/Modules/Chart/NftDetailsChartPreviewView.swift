import UIKit
import SnapKit
import Chart
import ThemeKit
import ComponentKit

class NftDetailsChartPreviewView: ChartPreviewView {
    override class func viewHeight() -> CGFloat {
        MarketCardTitleView.height  + .margin8
                + .heightOneDp + .margin8
                + MarketCardValueView.height + .margin4
                + ceil(UIFont.micro.lineHeight) + .margin12 + .margin8 + ChartPreviewView.viewHeight()
    }

    private let titleView = MarketCardTitleView()
    private let valueView = MarketCardValueView()
    private let currencyLabel = UILabel()

    required init(configuration: ChartConfiguration? = nil) {
        super.init(configuration: configuration)

        let separatorView = UIView()
        separatorView.snp.makeConstraints { maker in
            maker.height.equalTo(CGFloat.heightOneDp)
        }

        stackView.insertArrangedSubview(titleView, at: 0)
        stackView.insertArrangedSubview(separatorView, at: 1)
        stackView.insertArrangedSubview(valueView, at: 2)
        stackView.insertArrangedSubview(currencyLabel, at: 3)

        stackView.setCustomSpacing(.margin12 + .margin8, after: currencyLabel)
        stackView.setCustomSpacing(.margin4, after: valueView)

        currencyLabel.font = .micro
        currencyLabel.textColor = .themeGray

        separatorView.backgroundColor = .themeSteel20

        titleView.backgroundColor = .green
        valueView.backgroundColor = .greenSea
        currencyLabel.backgroundColor = .yellow
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func set(viewItem: ChartPreviewView.ViewItem) {
        super.set(viewItem: viewItem)

        guard let viewItem = viewItem as? ViewItem else {
            titleView.isHidden = true
            valueView.isHidden = true
            return
        }
        titleView.isHidden = viewItem.title == nil
        titleView.title = viewItem.title

        valueView.isHidden = false
        valueView.valueColor = viewItem.value == nil ? .themeGray50 : .themeBran
        valueView.value = viewItem.value ?? "n/a".localized

        valueView.diff = viewItem.diff
        valueView.diffColor = viewItem.diffColor

        currencyLabel.isHidden = viewItem.additionalValue == nil
        currencyLabel.text = viewItem.additionalValue
    }

}


extension NftDetailsChartPreviewView {

    class ViewItem: ChartPreviewView.ViewItem {
        let title: String?
        let value: String?
        let additionalValue: String?
        let diff: String
        let diffColor: UIColor

        init(title: String?, value: String?, additionalValue: String?, diff: String, diffColor: UIColor, data: ChartData?, trend: MovementTrend) {
            self.title = title
            self.value = value
            self.additionalValue = additionalValue
            self.diff = diff
            self.diffColor = diffColor

            super.init(data: data, trend: trend)
        }

    }

}
