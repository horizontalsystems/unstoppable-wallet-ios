import UIKit
import SnapKit

class CoinToggleCell: AppCell {
    private let coinImageView = CoinIconImageView()
    private let titleLabel = UILabel()
    private let coinLabel = UILabel()
    private let blockchainBadgeView = BadgeView()
    private let toggleView = UISwitch()

    private var onToggle: ((Bool) -> ())?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        contentView.addSubview(coinImageView)
        coinImageView.snp.makeConstraints { maker in
            maker.centerY.equalToSuperview()
            maker.leading.equalToSuperview().offset(CGFloat.margin4x)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.coinImageView.snp.trailing).offset(CGFloat.margin4x)
            maker.top.equalToSuperview().offset(CGFloat.margin2x)
        }

        titleLabel.textColor = .appOz
        titleLabel.font = .appBody

        contentView.addSubview(coinLabel)
        coinLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.titleLabel)
            maker.top.equalTo(self.titleLabel.snp.bottom).offset(3)
        }

        coinLabel.textColor = .appGray
        coinLabel.font = .appBody

        contentView.addSubview(blockchainBadgeView)
        blockchainBadgeView.snp.makeConstraints { maker in
            maker.leading.equalTo(coinLabel.snp.trailing).offset(CGFloat.margin1x)
            maker.centerY.equalTo(coinLabel.snp.centerY)
        }

        contentView.addSubview(toggleView)
        toggleView.snp.makeConstraints { maker in
            maker.trailing.equalToSuperview().offset(-CGFloat.margin4x)
            maker.centerY.equalToSuperview()
        }

        toggleView.tintColor = .cryptoSteel20
        toggleView.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    @objc func switchChanged() {
        onToggle?(toggleView.isOn)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func bind(coin: Coin, state: CoinToggleViewItemState, last: Bool, onToggle: ((Bool) -> ())? = nil) {
        switch state {
        case .toggleHidden:
            super.bind(showDisclosure: true, last: last)

            toggleView.isHidden = true
            selectionStyle = .default
        case .toggleVisible(let enabled):
            super.bind(last: last)

            toggleView.isHidden = false
            toggleView.setOn(enabled, animated: false)
            selectionStyle = .none
        }

        coinImageView.bind(coin: coin)
        titleLabel.text = coin.title
        coinLabel.text = coin.code

        if let blockchainType = coin.type.blockchainType {
            blockchainBadgeView.isHidden = false
            blockchainBadgeView.set(text: blockchainType)
        } else {
            blockchainBadgeView.isHidden = true
        }

        self.onToggle = onToggle
    }

}
