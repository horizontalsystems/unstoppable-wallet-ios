import UIKit
import ActionSheet

class ManageAccountsCreateAccountViewController: ActionSheetController {
    private let titleItem: AlertTitleItem
    private let textItem: AlertTextItem

    init(predefinedAccountType: IPredefinedAccountType, onCreate: @escaping () -> ()) {
        titleItem = AlertTitleItem(
                title: predefinedAccountType.title.localized,
                icon: UIImage(named: "Key Icon")?.withRenderingMode(.alwaysTemplate),
                iconTintColor: ManageAccountsTheme.alertKeyImageColor,
                tag: 0
        )

        textItem = AlertTextItem(text: "settings_manage_keys.create.text".localized(predefinedAccountType.coinCodes.localized), tag: 1)

        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        model.addItemView(titleItem)
        model.addItemView(textItem)

        let createItem = AlertButtonItem(
                tag: 2,
                title: "settings_manage_keys.create".localized,
                textStyle: ButtonTheme.textColorDictionary,
                backgroundStyle: ButtonTheme.yellowBackgroundDictionary,
                insets: UIEdgeInsets(top: ButtonTheme.verticalMargin, left: ButtonTheme.margin, bottom: ButtonTheme.verticalMargin, right: ButtonTheme.margin)
        ) { [weak self] in
            self?.dismiss(animated: true) {
                onCreate()
            }
        }

        createItem.isActive = true
        model.addItemView(createItem)
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
