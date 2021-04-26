import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class BackupRequiredViewController: ThemeActionSheetController {
    private let titleView = BottomSheetTitleView()
    private let descriptionView = HighlightedDescriptionView()
    private let backupButton = ThemeButton()

    private let account: Account
    private weak var sourceViewController: UIViewController?

    init(account: Account, text: String, sourceViewController: UIViewController?) {
        self.account = account
        self.sourceViewController = sourceViewController

        super.init()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.bind(
                title: "backup.backup_required".localized,
                subtitle: account.name,
                image: UIImage(named: "warning_2_24"),
                tintColor: .themeLucian
        )
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom).offset(CGFloat.margin12)
        }

        descriptionView.text = text

        view.addSubview(backupButton)
        backupButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin24)
            maker.bottom.equalToSuperview().inset(CGFloat.margin16)
            maker.height.equalTo(CGFloat.heightButton)
        }

        backupButton.apply(style: .primaryYellow)
        backupButton.setTitle("settings_manage_keys.backup".localized, for: .normal)
        backupButton.addTarget(self, action: #selector(onTapBackupButton), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapBackupButton() {
        dismiss(animated: true) { [weak self] in
            self?.openBackup()
        }
    }

    private func openBackup() {
        guard let viewController = BackupKeyModule.viewController(account: account) else {
            return
        }

        sourceViewController?.present(viewController, animated: true)
    }

}
