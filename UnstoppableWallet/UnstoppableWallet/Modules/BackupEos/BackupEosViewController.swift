import UIKit
import SnapKit
import ThemeKit
import UIExtensions

class BackupEosViewController: ThemeViewController {
    private let delegate: IBackupEosViewDelegate

    private let scrollView = UIScrollView()

    private let container = UIView()
    private let accountLabel = UILabel()
    private let accountField = FormField()
    private let activePrivateKeyLabel = UILabel()
    private let activePrivateKeyField = FormField()
    private let hintLabel = UILabel()
    private let qrCodeImageView = UIImageView()

    private let closeButtonHolder = BottomGradientHolder()
    private let closeButton = ThemeButton()

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

        accountLabel.text = "backup.eos.account_name".localized.uppercased()
        accountLabel.font = .subhead1
        accountLabel.textColor = .themeGray
        accountLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
            maker.top.equalToSuperview().offset(CGFloat.margin3x + CGFloat.margin2x) // simulate placement in header
        }

        accountField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(accountLabel.snp.bottom).offset(CGFloat.margin2x)
        }

        accountField.onTapCopy = { [weak self] in
            self?.delegate.onCopyAddress()
        }

        activePrivateKeyLabel.text = "backup.eos.active_private_key".localized.uppercased()
        activePrivateKeyLabel.font = .subhead1
        activePrivateKeyLabel.textColor = .themeGray
        activePrivateKeyLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(CGFloat.margin6x)
            maker.top.equalTo(self.accountField.snp.bottom).offset(CGFloat.margin3x + CGFloat.margin2x) // simulate placement in header
        }

        activePrivateKeyField.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
            maker.top.equalTo(activePrivateKeyLabel.snp.bottom).offset(CGFloat.margin2x)
        }

        activePrivateKeyField.onTapCopy = { [weak self] in
            self?.delegate.onCopyPrivateKey()
        }

        hintLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalTo(self.view).inset(CGFloat.margin6x)
            maker.top.equalTo(self.activePrivateKeyField.snp.bottom).offset(CGFloat.margin3x)
        }

        hintLabel.text = "backup.eos.hint".localized
        hintLabel.numberOfLines = 0
        hintLabel.font = .subhead2
        hintLabel.textColor = .themeGray

        qrCodeImageView.backgroundColor = .white
        qrCodeImageView.contentMode = .center
        qrCodeImageView.clipsToBounds = true
        qrCodeImageView.layer.cornerRadius = .cornerRadius1x
        qrCodeImageView.snp.makeConstraints { maker in
            maker.centerX.equalTo(self.view)
            maker.top.equalTo(hintLabel.snp.bottom).offset(CGFloat.margin6x)
            maker.size.equalTo(120)
        }

        view.addSubview(closeButtonHolder)
        closeButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(scrollView.snp.bottom).offset(-CGFloat.margin4x)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        closeButtonHolder.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.top.trailing.bottom.equalToSuperview().inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        closeButton.apply(style: .primaryYellow)
        closeButton.setTitle("backup.close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)

        accountField.text = delegate.account
        activePrivateKeyField.text = delegate.activePrivateKey
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
