import UIKit
import ActionSheet

class BackupRequiredViewController: ActionSheetController {

    init(subtitle: String, text: String, onBackup: @escaping () -> ()) {
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        let titleItem = AlertTitleItem(
                title: "backup.backup_required".localized,
                subtitle: subtitle,
                icon: UIImage(named: "Attention Icon")?.withRenderingMode(.alwaysTemplate),
                iconTintColor: BackupTheme.alertColor,
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
                insets: UIEdgeInsets(top: ButtonTheme.verticalMargin, left: ButtonTheme.margin, bottom: ButtonTheme.verticalMargin, right: ButtonTheme.margin)
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

        backgroundColor = AppTheme.actionSheetBackgroundColor
        contentBackgroundColor = .white
    }

}
