import UIKit
import SnapKit
import ThemeKit
import ComponentKit

class QrCodeCell: UITableViewCell {
    private static let horizontalMargin: CGFloat = .margin16
    private static let qrCodeSize: CGFloat = 150
    private static let tokenWrapperSize: CGFloat = 40
    private static let qrCodePadding: CGFloat = .margin4
    private static let qrCodeTopMargin: CGFloat = .margin32
    private static let qrCodeBottomMargin: CGFloat = .margin12
    private static let textBottomMargin: CGFloat = .margin24
    private static let textHorizontalMargin: CGFloat = .margin24
    private static let textFont: UIFont = .subhead2

    private let qrImageView = UIImageView()
    private let tokenImageView = UIImageView()
    private let label = UILabel()

    var onTap: (() -> ())?

    override init(style: CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear
        selectionStyle = .none

        let wrapperView = UIView()
        contentView.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Self.horizontalMargin)
            make.top.bottom.equalToSuperview()
        }

        wrapperView.borderColor = .themeSteel20
        wrapperView.borderWidth = .heightOneDp
        wrapperView.cornerRadius = .cornerRadius24
        wrapperView.cornerCurve = .continuous

        let qrCodeWrapperView = UIView()
        wrapperView.addSubview(qrCodeWrapperView)
        qrCodeWrapperView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().inset(Self.qrCodeTopMargin)
            make.width.equalTo(qrCodeWrapperView.snp.height)
            make.size.equalTo(Self.qrCodeSize)
        }

        qrCodeWrapperView.isUserInteractionEnabled = true
        qrCodeWrapperView.backgroundColor = .white
        qrCodeWrapperView.layer.cornerRadius = .cornerRadius8
        qrCodeWrapperView.layer.cornerCurve = .continuous

        let qrCodeRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapQrCode))
        qrImageView.addGestureRecognizer(qrCodeRecognizer)

        qrCodeWrapperView.addSubview(qrImageView)
        qrImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Self.qrCodePadding)
        }

        qrImageView.isUserInteractionEnabled = true
        qrImageView.backgroundColor = .white
        qrImageView.contentMode = .center

        let tokenWrapperView = UIView()
        qrImageView.addSubview(tokenWrapperView)
        tokenWrapperView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(Self.tokenWrapperSize)
        }

        tokenWrapperView.isUserInteractionEnabled = false
        tokenWrapperView.cornerRadius = .cornerRadius8
        tokenWrapperView.backgroundColor = .themeWhite
        tokenWrapperView.clipsToBounds = true

        tokenWrapperView.addSubview(tokenImageView)
        tokenImageView.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
            maker.size.equalTo(CGFloat.iconSize32)
        }

        tokenImageView.contentMode = .scaleAspectFit
        tokenImageView.image = UIImage(named: AppIcon.main.imageName)
        tokenImageView.cornerRadius = 6

        wrapperView.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Self.textHorizontalMargin)
            make.top.equalTo(qrCodeWrapperView.snp.bottom).offset(Self.qrCodeBottomMargin)
        }

        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Self.textFont
        label.textColor = .themeGray
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapQrCode() {
        onTap?()
    }

    func set(qrCodeString: String, text: String) {
        let size = Self.qrCodeSize - 2 * Self.qrCodePadding
        qrImageView.asyncSetImage { UIImage.qrCodeImage(qrCodeString: qrCodeString, size: size) }

        label.text = text
    }

}

extension QrCodeCell {

    static func height(containerWidth: CGFloat, text: String) -> CGFloat {
        let textWidth = containerWidth - 2 * horizontalMargin - 2 * textHorizontalMargin
        let textHeight = text.height(forContainerWidth: textWidth, font: textFont)
        return qrCodeTopMargin + qrCodeSize + qrCodeBottomMargin + textHeight + textBottomMargin
    }

}
