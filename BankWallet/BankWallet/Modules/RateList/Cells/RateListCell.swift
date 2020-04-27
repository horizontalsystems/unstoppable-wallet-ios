import UIKit
import SnapKit
import ThemeKit

class RateListCell: ClaudeThemeCell {
    private let leftCoinView = LeftCoinCellView()
    private let rightView = RateListChangingCellView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftCoinView)
        leftCoinView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(rightView)
        rightView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.equalTo(leftCoinView.snp.trailing)
            maker.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(viewItem: RateViewItem, showIcon: Bool = true, last: Bool = false) {
        super.bind(last: last)

        leftCoinView.bind(coinTitle: viewItem.coinTitle, coinCode: viewItem.coinCode, blockchainType: viewItem.blockchainType, showIcon: showIcon)

        let rateString: String?
        let rateColor: UIColor
        if let rate = viewItem.rate {
            rateString = ValueFormatter.instance.format(currencyValue: rate, fractionPolicy: .threshold(high: 1000, low: 0.1), trimmable: false)
            rateColor = viewItem.rateExpired ? .themeGray50 : .themeLeah
        } else {
            rateString = "----"
            rateColor = .themeGray50
        }

        rightView.bind(rate: rateString, rateColor: rateColor, diff: !viewItem.rateExpired ? viewItem.diff : nil)
    }

}
