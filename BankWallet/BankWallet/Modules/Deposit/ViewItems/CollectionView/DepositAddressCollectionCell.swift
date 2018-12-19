import UIKit
import SnapKit

class DepositAddressCollectionCell: UICollectionViewCell {
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var separatorView = UIView()
    var qrCodeImageView = UIImageView()
    var addressLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(iconImageView)
        iconImageView.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(DepositTheme.iconMargin)
            maker.top.equalToSuperview().offset(DepositTheme.iconMargin)
        }

        titleLabel.font = DepositTheme.titleFont
        titleLabel.textColor = DepositTheme.titleColor
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.iconImageView.snp.trailing).offset(DepositTheme.iconMargin)
            maker.centerY.equalTo(self.iconImageView.snp.centerY)
        }

        separatorView.backgroundColor = .cryptoLightGray
        contentView.addSubview(separatorView)
        separatorView.snp.makeConstraints { maker in
            maker.top.equalTo(self.iconImageView.snp.bottom).offset(DepositTheme.iconMargin)
            maker.left.right.equalToSuperview()
            maker.height.equalTo(0.5)
        }

        contentView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(self.separatorView.snp.bottom).offset(DepositTheme.qrCodeTopMargin)
            maker.size.equalTo(CGSize(width: DepositTheme.qrCodeSideSize, height: DepositTheme.qrCodeSideSize))
        }

        addressLabel.font = DepositTheme.addressFont
        addressLabel.textColor = DepositTheme.addressColor
        addressLabel.lineBreakMode = .byTruncatingMiddle
        addressLabel.textAlignment = .center
        contentView.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { maker in
            maker.top.equalTo(self.qrCodeImageView.snp.bottom).offset(DepositTheme.qrCodeBottomMargin)
            maker.left.equalToSuperview().offset(DepositTheme.addressSideMargin)
            maker.right.equalToSuperview().offset(-DepositTheme.addressSideMargin)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func bind(address: AddressItem) {
        iconImageView.image = UIImage(named: "\(address.coinCode) Icon")
        titleLabel.text = "deposit.receive_coin".localized(address.coinCode)
        qrCodeImageView.backgroundColor = .lightGray
        addressLabel.text = address.address

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
