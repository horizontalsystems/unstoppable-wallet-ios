import UIKit
import SnapKit

class DepositAddressCollectionCell: UICollectionViewCell {
    private let iconImageView = CoinIconImageView()
    var titleLabel = UILabel()
    var separatorView = UIView()
    var qrCodeImageView = UIImageView()
    var addressButton = AddressButton()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(DepositTheme.regularMargin)
            maker.top.equalToSuperview().offset(DepositTheme.regularMargin)
        }

        titleLabel.font = DepositTheme.titleFont
        titleLabel.textColor = DepositTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(DepositTheme.regularMargin)
            maker.centerY.equalTo(self.iconImageView.snp.centerY)
        }

        separatorView.backgroundColor = .cryptoSteel20
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.top.equalTo(self.iconImageView.snp.bottom).offset(DepositTheme.regularMargin)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        contentView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.separatorView.snp.bottom).offset(DepositTheme.qrCodeTopMargin)
            maker.size.equalTo(CGSize(width: DepositTheme.qrCodeSideSize, height: DepositTheme.qrCodeSideSize))
        }

        let addressTitleLabel = UILabel()
        addressTitleLabel.text = "deposit.your_address".localized
        addressTitleLabel.font = DepositTheme.addressTitleFont
        addressTitleLabel.textColor = DepositTheme.addressTitleColor
        addressTitleLabel.textAlignment = .center
        contentView.addSubview(addressTitleLabel)
        addressTitleLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.qrCodeImageView.snp.bottom).offset(DepositTheme.addressTitleTopMargin)
            maker.leading.trailing.equalToSuperview()
        }

        contentView.addSubview(addressButton)
        addressButton.snp.makeConstraints { maker in
            maker.top.equalTo(addressTitleLabel.snp.bottom).offset(DepositTheme.addressTopMargin)
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
        addressButton.bind(value: address.address)

        addressButton.onTap = onCopy

        qrCodeImageView.image = createQRFromString(address.address, size: CGSize(width: 150, height: 150))
    }

    func createQRFromString(_ str: String, size: CGSize) -> UIImage {
        let stringData = str.data(using: .utf8)

        let qrFilter = CIFilter(name: "CIQRCodeGenerator")!
        qrFilter.setValue(stringData, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")

        let minimalQRimage = qrFilter.outputImage!
        // NOTE that a QR code is always square, so minimalQRimage..width === .height
        let minimalSideLength = minimalQRimage.extent.width

        let smallestOutputExtent = (size.width < size.height) ? size.width : size.height
        let scaleFactor = smallestOutputExtent / minimalSideLength
        let scaledImage = minimalQRimage.transformed(
                by: CGAffineTransform(scaleX: scaleFactor, y: scaleFactor))

        return UIImage(ciImage: scaledImage,
                scale: UIScreen.main.scale,
                orientation: .up)
    }

}
