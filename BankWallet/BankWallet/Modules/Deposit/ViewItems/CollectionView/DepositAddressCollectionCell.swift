import UIKit
import SnapKit

class DepositAddressCollectionCell: UICollectionViewCell {
    private let iconImageView = CoinIconImageView()
    var titleLabel = UILabel()
    var separatorView = UIView()
    var qrCodeImageView = UIImageView()
    var addressButton = HashView()

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

        let addressTitleLabel = UILabel()
        addressTitleLabel.text = "deposit.your_address".localized
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
        qrCodeImageView.backgroundColor = .lightGray
        addressButton.bind(value: address.address, showExtra: .icon, onTap: onCopy)

        qrCodeImageView.image = UIImage(qrCodeString: address.address, size: DepositTheme.qrCodeSideSize)
    }

}
