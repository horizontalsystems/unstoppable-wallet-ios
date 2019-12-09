import UIKit
import SnapKit

class BackupEosViewController: WalletViewController {
    private let delegate: IBackupEosViewDelegate

    private let scrollView = UIScrollView()

    private let container = UIView()
    private let accountLabel = UILabel()
    private let accountField = AddressInputField(frame: .zero, placeholder: nil, showQrButton: false, canEdit: false, lineBreakMode: .byTruncatingMiddle, rightButtonMode: .copy)
    private let activePrivateKeyLabel = UILabel()
    private let activePrivateKeyField = AddressInputField(frame: .zero, placeholder: nil, numberOfLines: 2, showQrButton: false, canEdit: false, lineBreakMode: .byTruncatingMiddle, rightButtonMode: .copy)
    private let hintLabel = UILabel()
    private let qrCodeImageView = UIImageView()

    private let closeButtonHolder = GradientView(gradientHeight: .margin4x, viewHeight: .heightBottomWrapperBar, fromColor: UIColor.appTyler.withAlphaComponent(0), toColor: .appTyler)
    private let closeButton: UIButton = .appYellow

    init(delegate: IBackupEosViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.private_key".localized

        view.addSubview(scrollView)
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.snp.makeConstraints { maker in
            maker.top.equalToSuperview()
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        scrollView.addSubview(container)
        container.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.view)
            maker.top.bottom.equalTo(self.scrollView)
        }

        container.addSubview(accountLabel)
        container.addSubview(accountField)
        container.addSubview(activePrivateKeyLabel)
        container.addSubview(activePrivateKeyField)
        container.addSubview(hintLabel)
        container.addSubview(qrCodeImageView)

        view.addSubview(closeButtonHolder)
        closeButtonHolder.addSubview(closeButton)

        accountLabel.text = "backup.eos.account_name".localized.uppercased()
        accountLabel.font = .appSubhead1
        accountLabel.textColor = .appGray
        accountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x + CGFloat.margin2x) // simulate placement in header
        }
        accountField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(self.accountLabel.snp.bottom).offset(CGFloat.margin2x)
            maker.height.equalTo(44)
        }
        accountField.onCopy = { [weak self] in
            self?.delegate.onCopyAddress()
        }

        activePrivateKeyLabel.text = "backup.eos.active_private_key".localized.uppercased()
        activePrivateKeyLabel.font = .appSubhead1
        activePrivateKeyLabel.textColor = .appGray
        activePrivateKeyLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
            maker.top.equalTo(self.accountField.snp.bottom).offset(CGFloat.margin3x + CGFloat.margin2x) // simulate placement in header
        }
        activePrivateKeyField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(self.activePrivateKeyLabel.snp.bottom).offset(CGFloat.margin2x)
            maker.height.equalTo(66)
        }
        activePrivateKeyField.onCopy = { [weak self] in
            self?.delegate.onCopyPrivateKey()
        }

        hintLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.view).inset(CGFloat.margin6x)
            maker.top.equalTo(self.activePrivateKeyField.snp.bottom).offset(CGFloat.margin3x)
        }

        hintLabel.text = "backup.eos.hint".localized
        hintLabel.numberOfLines = 0
        hintLabel.font = .appSubhead2
        hintLabel.textColor = .appGray

        qrCodeImageView.backgroundColor = .white
        qrCodeImageView.contentMode = .center
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = .cornerRadius4
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalTo(self.view)
            maker.top.equalTo(hintLabel.snp.bottom).offset(CGFloat.margin6x)
            maker.size.equalTo(120)
            maker.bottom.equalToSuperview().inset(CGFloat.heightBottomWrapperBar)
        }

        closeButtonHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightBottomWrapperBar)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        closeButton.setTitle("backup.close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        closeButton.snp.makeConstraints { maker in
            maker.leading.trailing.bottom.equalToSuperview().inset(CGFloat.marginButtonSide)
            maker.height.equalTo(CGFloat.heightButton)
        }

        accountField.bind(address: delegate.account, error: nil)
        activePrivateKeyField.bind(address: delegate.activePrivateKey, error: nil)
        qrCodeImageView.asyncSetImage { UIImage(qrCodeString: self.delegate.activePrivateKey, size: 120) }
    }

    @objc func didTapClose() {
        delegate.didTapClose()
    }

}

extension BackupEosViewController: IBackupEosView {

    func showCopied() {
        HudHelper.instance.showSuccess(title: "alert.copied".localized)
    }

}
