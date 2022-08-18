import UIKit
import ThemeKit
import SnapKit
import ComponentKit

class BackupPromptViewController: ThemeActionSheetController {
    private let account: Account
    private weak var sourceViewController: UIViewController?

    init(account: Account, sourceViewController: UIViewController?) {
        self.account = account
        self.sourceViewController = sourceViewController

        super.init()

        let titleView = BottomSheetTitleView()

        view.addSubview(titleView)
        titleView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        titleView.title = "backup_prompt.title".localized
        titleView.image = UIImage(named: "warning_2_24")?.withTintColor(.themeJacob)
        titleView.onTapClose = { [weak self] in
            self?.dismiss(animated: true)
        }

        let descriptionView = HighlightedDescriptionView()

        view.addSubview(descriptionView)
        descriptionView.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin16)
            maker.top.equalTo(titleView.snp.bottom)
        }

        descriptionView.text = "backup_prompt.warning".localized

        let backupButton = PrimaryButton()

        view.addSubview(backupButton)
        backupButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(descriptionView.snp.bottom).offset(CGFloat.margin24)
        }

        backupButton.set(style: .yellow)
        backupButton.setTitle("backup_prompt.backup".localized, for: .normal)
        backupButton.addTarget(self, action: #selector(onTapBackup), for: .touchUpInside)

        let riskButton = PrimaryButton()

        view.addSubview(riskButton)
        riskButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin24)
            maker.top.equalTo(backupButton.snp.bottom).offset(CGFloat.margin12)
            maker.bottom.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin16)
        }

        riskButton.set(style: .transparent)
        riskButton.setTitle("backup_prompt.later".localized, for: .normal)
        riskButton.addTarget(self, action: #selector(onTapLater), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func onTapBackup() {
        dismiss(animated: true) { [weak self] in
            self?.openBackup()
        }
    }

    @objc private func onTapLater() {
        dismiss(animated: true)
    }

    private func openBackup() {
        guard let viewController = BackupModule.viewController(account: account) else {
            return
        }

        sourceViewController?.present(viewController, animated: true)
    }

}
