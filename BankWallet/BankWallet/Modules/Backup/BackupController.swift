import UIKit
import SnapKit

class BackupController: WalletViewController {
    private let delegate: IBackupViewDelegate

    private let subtitleLabel = UILabel()
    private let cancelButton: UIButton = .appGray
    private let proceedButton: UIButton = .appYellow

    init(delegate: IBackupViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = delegate.isBackedUp ? "backup.intro.title_show".localized : "backup.intro.title_backup".localized

        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(subtitleLabel)
        subtitleLabel.text = "backup.intro.subtitle".localized(delegate.coinCodes)
        subtitleLabel.font = BackupTheme.descriptionFont
        subtitleLabel.textColor = BackupTheme.descriptionColor
        subtitleLabel.numberOfLines = 0
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.top.equalTo(self.view.snp.topMargin).offset(BackupTheme.introDescriptionTopMargin)
        }

        view.addSubview(cancelButton)
        cancelButton.setTitle(delegate.isBackedUp ? "backup.close".localized : "backup.intro.later".localized, for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelDidTap), for: .touchUpInside)

        cancelButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.sideMargin)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-BackupTheme.sideMargin)
            maker.size.equalTo(CGSize(width: BackupTheme.laterButtonWidth, height: BackupTheme.buttonHeight))
        }

        view.addSubview(proceedButton)
        proceedButton.setTitle(delegate.isBackedUp ? "backup.intro.show_key".localized : "backup.intro.backup_now".localized, for: .normal)
        proceedButton.addTarget(self, action: #selector(proceedDidTap), for: .touchUpInside)

        proceedButton.snp.makeConstraints { maker in
            maker.leading.equalTo(cancelButton.snp.trailing).offset(BackupTheme.buttonsGap)
            maker.trailing.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-BackupTheme.sideMargin)
            maker.height.equalTo(BackupTheme.buttonHeight)
        }
    }

    @objc func proceedDidTap() {
        delegate.proceedDidTap()
    }

    @objc func cancelDidTap() {
        delegate.cancelDidClick()
    }

}
