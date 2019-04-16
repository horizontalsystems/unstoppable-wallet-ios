import UIKit
import SnapKit

class ManageCoinCell: UITableViewCell {
    let titleLabel = UILabel()
    let coinLabel = UILabel()
    let coinImageView = CoinIconImageView()

    let topSeparatorView = UIView()
    let bottomSeparatorView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = ManageCoinsTheme.cellBackground

        titleLabel.textColor = ManageCoinsTheme.titleColor
        titleLabel.font = ManageCoinsTheme.titleFont
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(ManageCoinsTheme.regularOffset)
            maker.top.equalToSuperview().offset(ManageCoinsTheme.smallOffset)
        }

        coinLabel.textColor = ManageCoinsTheme.coinLabelColor
        coinLabel.font = ManageCoinsTheme.coinLabelFont
        contentView.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(ManageCoinsTheme.coinLabelTopMargin)
        }

        contentView.addSubview(coinImageView)
        coinImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.trailing.equalToSuperview().offset(-ManageCoinsTheme.iconRightMargin)
        }

        topSeparatorView.backgroundColor = AppTheme.separatorColor
        addSubview(topSeparatorView)
        topSeparatorView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
        addSubview(bottomSeparatorView)
        bottomSeparatorView.snp.makeConstraints { maker in
            maker.leading.bottom.trailing.equalToSuperview()
            maker.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(coin: Coin, first: Bool, last: Bool) {
        titleLabel.text = coin.title
        coinLabel.text = coin.code
        coinImageView.bind(coin: coin)

        topSeparatorView.isHidden = !first
        bottomSeparatorView.backgroundColor = last ? AppTheme.darkSeparatorColor : AppTheme.separatorColor
    }

}
