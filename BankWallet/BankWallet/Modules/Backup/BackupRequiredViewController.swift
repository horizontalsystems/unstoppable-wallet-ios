import UIKit
import ActionSheet

class BackupRequiredViewController: WalletActionSheetController {

    init(subtitle: String, text: String, onBackup: @escaping () -> ()) {
        super.init()

        let titleItem = AlertTitleItem(
                title: "backup.backup_required".localized,
                subtitle: subtitle,
                icon: UIImage(named: "Attention Icon")?.withRenderingMode(.alwaysTemplate),
                iconTintColor: .themeLucian,
                tag: 0,
                onClose: { [weak self] in
                    self?.dismiss(byFade: false)
                }
        )

        let textItem = AlertTextItem(text: text, tag: 1)

        model.addItemView(titleItem)
        model.addItemView(textItem)

        let backupItem = AlertButtonItem(
                tag: 2,
                title: "settings_manage_keys.backup".localized,
                createButton: { .appYellow },
                insets: UIEdgeInsets(top: CGFloat.margin4x, left: CGFloat.margin4x, bottom: CGFloat.margin4x, right: CGFloat.margin4x)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                onBackup()
            }
        }

        backupItem.isEnabled = true
        model.addItemView(backupItem)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentBackgroundColor = .white
    }

}
