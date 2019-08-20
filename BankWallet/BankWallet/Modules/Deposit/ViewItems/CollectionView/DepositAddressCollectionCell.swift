import UIKit
import SnapKit

class DepositAddressCollectionCell: UICollectionViewCell {
    private let iconImageView = CoinIconImageView()
    private let titleLabel = UILabel()
    private let separatorView = UIView()
    private let qrCodeImageView = UIImageView()
    private let addressTitleLabel = UILabel()
    private let addressButton = HashView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(DepositTheme.mediumMargin)
            maker.top.equalToSuperview().offset(DepositTheme.mediumMargin)
        }

        titleLabel.font = DepositTheme.titleFont
        titleLabel.textColor = DepositTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(DepositTheme.titleLeadingMargin)
            maker.centerY.equalTo(self.iconImageView.snp.centerY)
        }

        separatorView.backgroundColor = .cryptoSteel20
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.top.equalTo(self.iconImageView.snp.bottom).offset(DepositTheme.mediumMargin)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        contentView.addSubview(qrCodeImageView)
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = DepositTheme.qrCornerRadius
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.separatorView.snp.bottom).offset(DepositTheme.regularMargin)
            maker.size.equalTo(DepositTheme.qrCodeSideSize)
        }

        addressTitleLabel.font = DepositTheme.addressTitleFont
        addressTitleLabel.textColor = DepositTheme.addressTitleColor
        addressTitleLabel.textAlignment = .center
        contentView.addSubview(addressTitleLabel)
        addressTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.qrCodeImageView.snp.bottom).offset(DepositTheme.mediumMargin)
            maker.leading.trailing.equalToSuperview()
        }

        contentView.addSubview(addressButton)
        addressButton.snp.makeConstraints { maker in
            maker.top.equalTo(addressTitleLabel.snp.bottom).offset(DepositTheme.mediumMargin)
            maker.leading.equalToSuperview().offset(DepositTheme.regularMargin).priority(.high)
            maker.trailing.equalToSuperview().offset(-DepositTheme.regularMargin).priority(.high)
            maker.centerX.equalToSuperview()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(address: AddressItem, onCopy: @escaping () -> ()) {
        iconImageView.bind(coin: address.coin)
        titleLabel.text = "deposit.receive_coin".localized(address.coin.title)
        qrCodeImageView.backgroundColor = .white
        addressTitleLabel.text = addressTitle(coin: address.coin)
        addressButton.bind(value: address.address, showExtra: .icon, onTap: onCopy)

        qrCodeImageView.asyncSetImage { UIImage(qrCodeString: address.address, size: DepositTheme.qrCodeSideSize) }
    }

    private func addressTitle(coin: Coin) -> String {
        switch coin.type {
        case .eos: return "deposit.your_account".localized
        default: return "deposit.your_address".localized
        }
    }

}
