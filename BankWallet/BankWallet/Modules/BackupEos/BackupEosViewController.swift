import UIKit
import SnapKit

class BackupEosViewController: WalletViewController {
    private let delegate: IBackupEosViewDelegate

    private let accountLabel = UILabel()
    private let accountField = AddressInputField(frame: .zero, placeholder: nil, showQrButton: false, canEdit: false, lineBreakMode: .byTruncatingMiddle, rightButtonMode: .copy)
    private let activePrivateKeyLabel = UILabel()
    private let activePrivateKeyField = AddressInputField(frame: .zero, placeholder: nil, numberOfLines: 2, showQrButton: false, canEdit: false, lineBreakMode: .byTruncatingMiddle, rightButtonMode: .copy)
    private let hintLabel = UILabel()
    private let qrCodeImageView = UIImageView()

    init(delegate: IBackupEosViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "backup.eos.title".localized

        view.addSubview(accountLabel)
        view.addSubview(accountField)
        view.addSubview(activePrivateKeyLabel)
        view.addSubview(activePrivateKeyField)
        view.addSubview(hintLabel)
        view.addSubview(qrCodeImageView)

        accountLabel.text = "backup.eos.account_name".localized
        accountLabel.font = BackupTheme.eosTextFont
        accountLabel.textColor = BackupTheme.eosTextColor
        accountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.eosRegularMargin + BackupTheme.eosSubtitleHorizontalMargin)
            maker.top.equalTo(self.view.snp.topMargin).offset(BackupTheme.accountTopMargin)
        }
        accountField.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.eosRegularMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.eosRegularMargin)
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
            maker.leading.equalToSuperview().offset(BackupTheme.eosRegularMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.eosRegularMargin)
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
            maker.leading.equalToSuperview().offset(BackupTheme.eosRegularMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.eosRegularMargin)
            maker.top.equalTo(self.activePrivateKeyField.snp.bottom).offset(BackupTheme.eosRegularMargin)
        }

        qrCodeImageView.backgroundColor = .lightGray
        qrCodeImageView.contentMode = .center
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = BackupTheme.eosQrCodeCornerRadius
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(hintLabel.snp.bottom).offset(BackupTheme.eosQrCodeTopMargin)
            maker.size.equalTo(BackupTheme.eosQrCodeSize)
        }

        qrCodeImageView.image = UIImage(qrCodeString: delegate.activePrivateKey, size: BackupTheme.eosQrCodeSize)
        accountField.bind(address: delegate.account, error: nil)
        activePrivateKeyField.bind(address: delegate.activePrivateKey, error: nil)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func didTapClose() {
        delegate.didTapClose()
    }

}
