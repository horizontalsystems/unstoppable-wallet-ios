import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class DepositViewController: ThemeActionSheetController {
    private static let qrCodeSideSize: CGFloat = 120

    private let delegate: IDepositViewDelegate

    private let titleView = BottomSheetTitleView()
    private let qrCodeImageView = UIImageView()
    private let addressTitleLabel = UILabel()
    private let addressButton = ThemeButton()
    private let shareButton = ThemeButton()

    init(delegate: IDepositViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.onTapClose = { [weak self] in
            self?.delegate.onTapClose()
        }

        view.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin4x)
            maker.size.equalTo(DepositViewController.qrCodeSideSize)
        }

        qrCodeImageView.backgroundColor = .white
        qrCodeImageView.contentMode = .center
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = .cornerRadius1x

        view.addSubview(addressTitleLabel)
        addressTitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(qrCodeImageView.snp.bottom).offset(CGFloat.margin4x)
        }

        addressTitleLabel.font = .subhead2
        addressTitleLabel.textColor = .themeGray
        addressTitleLabel.textAlignment = .center

        view.addSubview(addressButton)
        addressButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x).priority(.medium)
            maker.centerX.equalToSuperview()
            maker.top.equalTo(addressTitleLabel.snp.bottom).offset(CGFloat.margin3x)
        }

        addressButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        addressButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        addressButton.addTarget(self, action: #selector(onTapAddress), for: .touchUpInside)

        addressButton.apply(style: .secondaryDefault)
        addressButton.titleLabel?.numberOfLines = 0

        // By default UIButton has no constraints to its titleLabel.
        // In order to support multiline title the following constraints are required
        addressButton.titleLabel?.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(addressButton.contentEdgeInsets)
        }

        view.addSubview(shareButton)
        shareButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(addressButton.snp.bottom).offset(CGFloat.margin6x)
            maker.bottom.equalToSuperview().inset(CGFloat.margin4x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        shareButton.apply(style: .primaryGreen)
        shareButton.setTitle("button.share".localized, for: .normal)
        shareButton.addTarget(self, action: #selector(onTapShare), for: .touchUpInside)

        delegate.onLoad()
    }

    @objc private func onTapAddress() {
        delegate.onTapAddress()
    }

    @objc private func onTapShare() {
        delegate.onTapShare()
    }

}

extension DepositViewController: IDepositView {

    func set(viewItem: DepositModule.AddressViewItem) {
        titleView.bind(
                title: "deposit.receive_coin".localized(viewItem.coinCode),
                subtitle: viewItem.coinTitle,
                image: .image(coinType: viewItem.coinType)
        )

        var addressTitle = "deposit.your_address".localized

        if let additionalInfo = viewItem.additionalInfo {
            addressTitle += " (\(additionalInfo))"
        }

        addressTitleLabel.text = addressTitle
        addressButton.setTitle(viewItem.address, for: .normal)

        qrCodeImageView.asyncSetImage { UIImage(qrCodeString: viewItem.address, size: DepositViewController.qrCodeSideSize) }
    }

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
