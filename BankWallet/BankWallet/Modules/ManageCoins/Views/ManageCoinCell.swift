import UIKit
import SnapKit

class ManageCoinCell: UITableViewCell {
    let titleLabel = UILabel()
    let coinLabel = UILabel()
    let coinImageView = CoinIconImageView()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(coin: Coin) {
        titleLabel.text = coin.title
        coinLabel.text = coin.code
        coinImageView.bind(coin: coin)
    }

}
