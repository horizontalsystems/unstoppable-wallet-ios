import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class DepositViewController: ThemeViewController {
    private let qrCodeSideMargin: CGFloat = 72

    private let viewModel: DepositViewModel

    init(viewModel: DepositViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let iconImageView = UIImageView()

        title = "deposit.receive_coin".localized(viewModel.coin.code)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: iconImageView)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        iconImageView.image = .image(coinType: viewModel.coin.type)

        let topWrapperView = UIView()

        view.addSubview(topWrapperView)
        topWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
        }

        let bottomWrapperView = UIView()

        view.addSubview(bottomWrapperView)
        bottomWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(topWrapperView.snp.bottom)
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        let contentWrapperView = UIView()

        topWrapperView.addSubview(contentWrapperView)
        contentWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        let qrCodeImageView = UIImageView()

        contentWrapperView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(qrCodeSideMargin)
            maker.top.equalToSuperview()
            maker.width.equalTo(qrCodeImageView.snp.height)
        }

        qrCodeImageView.backgroundColor = .white
        qrCodeImageView.contentMode = .center
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = .cornerRadius8

        let address = viewModel.address
        let size = view.width - 2 * qrCodeSideMargin
        qrCodeImageView.asyncSetImage { UIImage.qrCodeImage(qrCodeString: address, size: size)  }

        if !viewModel.isMainNet {
            let testnetImageView = UIImageView()

            view.addSubview(testnetImageView)
            testnetImageView.snp.makeConstraints { maker in
                maker.top.equalTo(qrCodeImageView.snp.bottom)
                maker.centerX.equalToSuperview()
            }

            testnetImageView.image = UIImage(named: "testnet_24")?.withRenderingMode(.alwaysTemplate)
            testnetImageView.tintColor = .themeRed50
        }

        let addressTitleLabel = UILabel()

        contentWrapperView.addSubview(addressTitleLabel)
        addressTitleLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(qrCodeImageView.snp.bottom).offset(CGFloat.margin24)
        }

        addressTitleLabel.textAlignment = .center
        addressTitleLabel.numberOfLines = 0
        addressTitleLabel.font = .subhead2
        addressTitleLabel.textColor = viewModel.isMainNet ? .themeGray : .themeLucian

        var addressTitle = "deposit.your_address".localized

        if let additionalInfo = viewModel.additionalInfo {
            addressTitle += " (\(additionalInfo))"
        }

        addressTitleLabel.text = addressTitle

        let addressLabel = UILabel()

        contentWrapperView.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(addressTitleLabel.snp.bottom).offset(CGFloat.margin12)
        }

        addressLabel.textAlignment = .center
        addressLabel.numberOfLines = 0
        addressLabel.font = .subhead1
        addressLabel.textColor = .themeBran
        addressLabel.text = viewModel.address

        let buttonsWrapper = UIView()

        contentWrapperView.addSubview(buttonsWrapper)
        buttonsWrapper.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(addressLabel.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalToSuperview()
        }

        let copyButton = ThemeButton()

        buttonsWrapper.addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        copyButton.apply(style: .secondaryDefault)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)

        let shareButton = ThemeButton()

        buttonsWrapper.addSubview(shareButton)
        shareButton.snp.makeConstraints { maker in
            maker.leading.equalTo(copyButton.snp.trailing).offset(CGFloat.margin12)
            maker.trailing.equalToSuperview()
            maker.top.equalToSuperview()
        }

        shareButton.apply(style: .secondaryDefault)
        shareButton.setTitle("button.share".localized, for: .normal)
        shareButton.addTarget(self, action: #selector(onTapShare), for: .touchUpInside)

        let closeButton = ThemeButton()

        bottomWrapperView.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin24)
            maker.height.equalTo(CGFloat.heightButton)
        }

        closeButton.apply(style: .primaryYellow)
        closeButton.setTitle("button.close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(onTapClose), for: .touchUpInside)
    }

    @objc private func onTapCopy() {
        UIPasteboard.general.setValue(viewModel.address, forPasteboardType: "public.plain-text")
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

    @objc private func onTapShare() {
        let activityViewController = UIActivityViewController(activityItems: [viewModel.address], applicationActivities: [])
        present(activityViewController, animated: true, completion: nil)
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

}
