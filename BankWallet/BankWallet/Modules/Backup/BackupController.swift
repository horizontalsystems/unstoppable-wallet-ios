import UIKit
import SnapKit

class BackupController: WalletViewController {

    let delegate: IBackupViewDelegate

    let subtitleLabel = UILabel()
    let laterButton = UIButton()
    let backupButton = UIButton()

    init(delegate: IBackupViewDelegate) {
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "backup.intro.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(subtitleLabel)
        subtitleLabel.text = "backup.intro.subtitle".localized
        subtitleLabel.font = BackupTheme.descriptionFont
        subtitleLabel.textColor = BackupTheme.descriptionColor
        subtitleLabel.numberOfLines = 0
        subtitleLabel.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.sideMargin)
            maker.trailing.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.top.equalTo(self.view.snp.topMargin).offset(BackupTheme.introDescriptionTopMargin)
        }

        view.addSubview(laterButton)
        laterButton.setTitle("backup.intro.later".localized, for: .normal)
        laterButton.cornerRadius = BackupTheme.buttonCornerRadius
        laterButton.setBackgroundColor(color: BackupTheme.laterButtonBackground, forState: .normal)
        laterButton.addTarget(self, action: #selector(cancelDidTap), for: .touchUpInside)
        laterButton.setTitleColor(BackupTheme.buttonTitleColor, for: .normal)
        laterButton.titleLabel?.font = BackupTheme.buttonTitleFont
        laterButton.snp.makeConstraints { maker in
            maker.leading.equalToSuperview().offset(BackupTheme.sideMargin)
            maker.bottom.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.size.equalTo(CGSize(width: BackupTheme.laterButtonWidth, height: BackupTheme.buttonHeight))
        }

        view.addSubview(backupButton)
        backupButton.setTitle("backup.intro.backup_now".localized, for: .normal)
        backupButton.cornerRadius = BackupTheme.buttonCornerRadius
        backupButton.setBackgroundColor(color: BackupTheme.backupButtonBackground, forState: .normal)
        backupButton.addTarget(self, action: #selector(backupDidTap), for: .touchUpInside)
        backupButton.setTitleColor(BackupTheme.buttonTitleColor, for: .normal)
        backupButton.titleLabel?.font = BackupTheme.buttonTitleFont
        backupButton.snp.makeConstraints { maker in
            maker.leading.equalTo(laterButton.snp.trailing).offset(BackupTheme.buttonsGap)
            maker.trailing.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.bottom.equalToSuperview().offset(-BackupTheme.sideMargin)
            maker.height.equalTo(BackupTheme.buttonHeight)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @objc func backupDidTap() {
        delegate.backupDidTap()
    }

    @objc func cancelDidTap() {
        delegate.cancelDidClick()
    }

}
