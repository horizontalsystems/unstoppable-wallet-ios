import UIKit
import ActionSheet

class BackupRequiredViewController: ActionSheetController {
    private let titleItem: AlertTitleItem
    private let textItem: AlertTextItem

    init(text: String, onBackup: @escaping () -> ()) {
        titleItem = AlertTitleItem(
                title: "backup.backup_required".localized,
                icon: UIImage(named: "Attention Icon")?.withRenderingMode(.alwaysTemplate),
                iconTintColor: BackupTheme.alertColor,
                tag: 0
        )

        textItem = AlertTextItem(text: text, tag: 1)

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
