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

        qrCodeImageView.image = createQRFromString(wallet, size: CGSize(width: 150, height: 150))
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
