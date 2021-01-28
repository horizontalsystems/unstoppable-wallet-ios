import UIKit
import SnapKit
import ThemeKit

class RateListCell: BaseSelectableThemeCell {
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

    func bind(viewItem: RateListModule.CoinViewItem) {
        selectionStyle = viewItem.rate == nil ? .none : .default

        leftCoinView.bind(coinTitle: viewItem.coinTitle, coinCode: viewItem.coinCode, blockchainType: viewItem.blockchainType)
        rightView.bind(viewItem: viewItem.rate)
    }

}
