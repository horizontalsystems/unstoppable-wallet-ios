import UIKit
import SnapKit

class ManageWalletCell: AppCell {
    private let coinImageView = CoinIconImageView()
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()
    private let toggleView = UISwitch()

    private var onToggle: ((Bool) -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = ManageWalletsTheme.cellBackground

        contentView.addSubview(coinImageView)
        coinImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(ManageWalletsTheme.regularOffset)
        }

        titleLabel.textColor = ManageWalletsTheme.titleColor
        titleLabel.font = ManageWalletsTheme.titleFont
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.coinImageView.snp.trailing).offset(ManageWalletsTheme.regularOffset)
            maker.top.equalToSuperview().offset(ManageWalletsTheme.smallOffset)
        }

        coinLabel.textColor = ManageWalletsTheme.coinLabelColor
        coinLabel.font = ManageWalletsTheme.coinLabelFont
        contentView.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(ManageWalletsTheme.coinLabelTopMargin)
        }

        toggleView.tintColor = SettingsTheme.switchTintColor
        toggleView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
        contentView.addSubview(toggleView)
        toggleView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-ManageWalletsTheme.regularOffset)
            maker.centerY.equalToSuperview()
        }
    }

    @objc func switchChanged() {
        onToggle?(toggleView.isOn)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(item: ManageWalletViewItem, first: Bool, last: Bool, onToggle: @escaping (Bool) -> ()) {
        super.bind(last: last)

        let coin = item.coin

        titleLabel.text = coin.title
        coinLabel.text = coin.code
        coinImageView.bind(coin: coin)
        toggleView.setOn(item.enabled, animated: false)

        self.onToggle = onToggle
    }

}
