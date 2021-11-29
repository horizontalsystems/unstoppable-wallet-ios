import UIKit
import ThemeKit
import SnapKit
import ComponentKit
import Alamofire
import Kingfisher

class DepositViewController: ThemeViewController {
    private let qrCodeSideMargin: CGFloat = 72
    private let smallScreenQrCodeSideMargin: CGFloat = 88

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

        title = "deposit.receive_coin".localized(viewModel.coin.code)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        let imageView = UIImageView()
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: imageView)

        imageView.kf.setImage(
                with: URL(string: viewModel.coin.imageUrl),
                placeholder: UIImage(named: viewModel.coinType.placeholderImageName),
                options: [.scaleFactor(UIScreen.main.scale)]
        )

        let topWrapperView = UIView()

        view.addSubview(topWrapperView)
        topWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide)
        }

        let contentWrapperView = UIView()

        topWrapperView.addSubview(contentWrapperView)
        contentWrapperView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
        }

        let margin = view.width > 320 ? qrCodeSideMargin : smallScreenQrCodeSideMargin
        let qrCodeImageView = UIImageView()

        contentWrapperView.addSubview(qrCodeImageView)
        qrCodeImageView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(margin)
            maker.top.equalToSuperview()
            maker.width.equalTo(qrCodeImageView.snp.height)
        }

        qrCodeImageView.isUserInteractionEnabled = true
        qrCodeImageView.backgroundColor = .white
        qrCodeImageView.contentMode = .center
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = .cornerRadius8

        let qrCodeRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapCopy))
        qrCodeImageView.addGestureRecognizer(qrCodeRecognizer)

        let address = viewModel.address


        let size = view.width - 2 * margin

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

        let addressLabelWrapper = UIView()

        contentWrapperView.addSubview(addressLabelWrapper)
        addressLabelWrapper.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.top.equalTo(addressTitleLabel.snp.bottom)
            maker.bottom.equalToSuperview()
        }

        let addressRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTapCopy))
        addressLabelWrapper.isUserInteractionEnabled = true
        addressLabelWrapper.addGestureRecognizer(addressRecognizer)

        let addressLabel = UILabel()

        addressLabelWrapper.addSubview(addressLabel)
        addressLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.bottom.equalToSuperview().inset(CGFloat.margin12)
        }

        addressLabel.textAlignment = .center
        addressLabel.numberOfLines = 0
        addressLabel.font = .subhead1
        addressLabel.textColor = .themeBran
        addressLabel.text = viewModel.address

        let copyButton = ThemeButton()

        view.addSubview(copyButton)
        copyButton.snp.makeConstraints { maker in
            maker.top.equalTo(topWrapperView.snp.bottom).offset(CGFloat.margin24)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
        }

        copyButton.apply(style: .primaryYellow)
        copyButton.setTitle("button.copy".localized, for: .normal)
        copyButton.addTarget(self, action: #selector(onTapCopy), for: .touchUpInside)
        copyButton.setContentHuggingPriority(.defaultHigh, for: .vertical)
        let shareButton = ThemeButton()

        view.addSubview(shareButton)
        shareButton.snp.makeConstraints { maker in
            maker.top.equalTo(copyButton.snp.bottom).offset(CGFloat.margin16)
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.bottom.equalToSuperview().inset(44)
        }

        shareButton.apply(style: .primaryGray)
        shareButton.setTitle("button.share".localized, for: .normal)
        shareButton.addTarget(self, action: #selector(onTapShare), for: .touchUpInside)
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
