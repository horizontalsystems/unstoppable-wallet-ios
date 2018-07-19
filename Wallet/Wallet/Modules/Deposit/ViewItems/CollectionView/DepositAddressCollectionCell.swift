import UIKit
import SnapKit

class DepositAddressCollectionCell: UICollectionViewCell {
    var titleLabel = UILabel()
    var qrCodeImageView = UIImageView()
    var addressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel.font = DepositTheme.titleFont
        titleLabel.textColor = DepositTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(DepositTheme.titleTopMargin)
        }

        contentView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(DepositTheme.qrCodeVerticalMargin)
            maker.size.equalTo(CGSize(width: DepositTheme.qrCodeSideSize, height: DepositTheme.qrCodeSideSize))
        }

        addressLabel.font = DepositTheme.addressFont
        addressLabel.textColor = DepositTheme.addressColor
        contentView.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.qrCodeImageView.snp.bottom).offset(DepositTheme.qrCodeVerticalMargin)
            maker.centerX.equalToSuperview()
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(wallet: String) {
        titleLabel.text = "some wallet"
        qrCodeImageView.backgroundColor = .lightGray
        addressLabel.text = wallet
    }

}
