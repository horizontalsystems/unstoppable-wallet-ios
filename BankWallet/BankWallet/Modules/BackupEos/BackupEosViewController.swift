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

    private let closeButtonHolder = GradientView(gradientHeight: BackupTheme.gradientHeight, viewHeight: BackupTheme.cancelHolderHeight, fromColor: BackupTheme.gradientTransparent, toColor: BackupTheme.gradientSolid)
    private let closeButton = UIButton()

    init(delegate: IBackupEosViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.eos.title".localized

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

        accountLabel.text = "backup.eos.account_name".localized
        accountLabel.font = BackupTheme.eosTextFont
        accountLabel.textColor = BackupTheme.eosTextColor
        accountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.eosRegularMargin + BackupTheme.eosSubtitleHorizontalMargin)
            maker.top.equalToSuperview().offset(BackupTheme.accountTopMargin)
        }
        accountField.snp.makeConstraints { maker in
            maker.leading.equalTo(self.view.snp.leading).offset(BackupTheme.eosRegularMargin)
            maker.trailing.equalTo(self.view.snp.trailing).offset(-BackupTheme.eosRegularMargin)
            maker.top.equalTo(self.accountLabel.snp.bottom).offset(BackupTheme.eosSmallMargin)
            maker.height.equalTo(44)
        }
        accountField.onCopy = { [weak self] in
            self?.delegate.onCopyAddress()
        }

        activePrivateKeyLabel.text = "backup.eos.active_private_key".localized
        activePrivateKeyLabel.font = BackupTheme.eosTextFont
        activePrivateKeyLabel.textColor = BackupTheme.eosTextColor
        activePrivateKeyLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.eosRegularMargin + BackupTheme.eosSubtitleHorizontalMargin)
            maker.top.equalTo(self.accountField.snp.bottom).offset(BackupTheme.activePrivateKeyLabelTopMargin)
        }
        activePrivateKeyField.snp.makeConstraints { maker in
            maker.leading.equalTo(self.view.snp.leading).offset(BackupTheme.eosRegularMargin)
            maker.trailing.equalTo(self.view.snp.trailing).offset(-BackupTheme.eosRegularMargin)
            maker.top.equalTo(self.activePrivateKeyLabel.snp.bottom).offset(BackupTheme.eosSmallMargin)
            maker.height.equalTo(66)
        }
        activePrivateKeyField.onCopy = { [weak self] in
            self?.delegate.onCopyPrivateKey()
        }

        hintLabel.text = "backup.eos.hint".localized
        hintLabel.numberOfLines = 0
        hintLabel.font = BackupTheme.eosTextFont
        hintLabel.textColor = BackupTheme.eosTextColor
        hintLabel.snp.makeConstraints { maker in
            maker.leading.equalTo(self.view.snp.leading).offset(BackupTheme.eosRegularMargin)
            maker.trailing.equalTo(self.view.snp.trailing).offset(-BackupTheme.eosRegularMargin)
            maker.top.equalTo(self.activePrivateKeyField.snp.bottom).offset(BackupTheme.eosRegularMargin)
        }

        qrCodeImageView.backgroundColor = .white
        qrCodeImageView.contentMode = .center
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = BackupTheme.eosQrCodeCornerRadius
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalTo(self.view)
            maker.top.equalTo(hintLabel.snp.bottom).offset(BackupTheme.eosQrCodeTopMargin)
            maker.size.equalTo(BackupTheme.eosQrCodeSize)
            maker.bottom.equalToSuperview().offset(-BackupTheme.cancelHolderHeight)
        }

        closeButtonHolder.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview()
            maker.height.equalTo(BackupTheme.cancelHolderHeight)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }

        closeButton.setTitle("backup.close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        closeButton.setBackgroundColor(color: BackupTheme.backupButtonBackground, forState: .normal)
        closeButton.setTitleColor(BackupTheme.buttonTitleColor, for: .normal)
        closeButton.titleLabel?.font = BackupTheme.buttonTitleFont
        closeButton.cornerRadius = BackupTheme.buttonCornerRadius
        closeButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.bottom.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.height.equalTo(BackupTheme.buttonHeight)
        }

        accountField.bind(address: delegate.account, error: nil)
        activePrivateKeyField.bind(address: delegate.activePrivateKey, error: nil)
        qrCodeImageView.asyncSetImage { UIImage(qrCodeString: self.delegate.activePrivateKey, size: BackupTheme.eosQrCodeSize) }
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
