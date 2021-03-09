import UIKit
import SnapKit
import ThemeKit
import CoinKit

class SwapTokenSelectCell: BaseSelectableThemeCell {
    private let leftCoinView = LeftCoinCellView()
    private let balanceView = RightValueCellView()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(leftCoinView)
        leftCoinView.snp.makeConstraints { maker in
            maker.leading.top.bottom.equalToSuperview()
        }

        contentView.addSubview(balanceView)
        balanceView.snp.makeConstraints { maker in
            maker.leading.equalTo(leftCoinView.snp.trailing)
            maker.trailing.centerY.equalToSuperview().inset(CGFloat.margin2x)
        }

        balanceView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(coin: Coin, balance: String?) {
        leftCoinView.bind(coinTitle: coin.title, coinCode: coin.code, coinType: coin.type, showBadge: false)
        balanceView.bind(text: balance, highlighted: true)
    }

}
