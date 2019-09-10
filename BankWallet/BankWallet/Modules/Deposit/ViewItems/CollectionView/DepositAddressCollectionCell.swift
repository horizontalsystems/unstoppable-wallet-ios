import UIKit
import SnapKit

class DepositAddressCollectionCell: UICollectionViewCell {
    private let titleView = AlertTitleView(frame: .zero)
    private let separatorView = UIView()

    private let qrCodeImageView = UIImageView()
    private let addressTitleLabel = UILabel()
    private let addressButton = HashView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.top.leading.trailing.equalToSuperview()
            maker.height.equalTo(AppTheme.alertTitleHeight)
        }
        separatorView.backgroundColor = .cryptoSteel20
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.top.equalTo(self.titleView.snp.bottom)
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

    func bind(address: AddressItem, onCopy: @escaping () -> (), onClose: (() -> ())?) {
        titleView.bind(
                title: "deposit.receive_coin".localized(address.coin.code), 
                subtitle: address.coin.title,
                image: UIImage(coin: address.coin),
                tintColor: nil,
                onClose: onClose)

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
