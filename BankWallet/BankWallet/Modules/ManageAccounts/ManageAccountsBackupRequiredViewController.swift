import UIKit
import ActionSheet

class ManageAccountsBackupRequiredViewController: ActionSheetController {
    private let titleItem: AlertTitleItem
    private let textItem: AlertTextItem

    init(title: String, onBackup: @escaping () -> ()) {
        titleItem = AlertTitleItem(
                title: title.localized,
                icon: UIImage(named: "Key Icon")?.withRenderingMode(.alwaysTemplate),
                iconTintColor: ManageAccountsTheme.alertKeyImageColor,
                tag: 0
        )

        textItem = AlertTextItem(text: "settings_manage_keys.delete.cant_delete".localized, tag: 1)

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        model.addItemView(titleItem)
        model.addItemView(textItem)

        let backupItem = AlertButtonItem(
                tag: 2,
                title: "settings_manage_keys.backup".localized,
                textStyle: ButtonTheme.textColorDictionary,
                backgroundStyle: ButtonTheme.yellowBackgroundDictionary,
                insets: UIEdgeInsets(top: ButtonTheme.verticalMargin, left: ButtonTheme.margin, bottom: ButtonTheme.verticalMargin, right: ButtonTheme.margin)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                onBackup()
            }
        }

        backupItem.isActive = true
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
