import UIKit
import ActionSheet

class UnlinkViewController: ActionSheetController {
    private let delegate: IUnlinkViewDelegate
    private var items = [ConfirmationCheckboxItem]()
    private var buttonItem: AlertButtonItem?

    init(delegate: IUnlinkViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        var texts = [NSAttributedString]()

        let attributes = [NSAttributedString.Key.foregroundColor: ConfirmationTheme.textColor, NSAttributedString.Key.font: ConfirmationTheme.regularFont]
        texts.append(NSAttributedString(string: "settings_manage_keys.delete.confirmation_remove".localized(delegate.title.localized), attributes: attributes))
        texts.append(NSAttributedString(string: "settings_manage_keys.delete.confirmation_disable".localized(delegate.coinCodes.localized), attributes: attributes))
        texts.append(NSAttributedString(string: "settings_manage_keys.delete.confirmation_loose".localized, attributes: attributes))

        for (index, text) in texts.enumerated() {
            let item = ConfirmationCheckboxItem(descriptionText: text, tag: index) { [weak self] view in
                self?.handleToggle(index: index)
            }

            model.addItemView(item)
            items.append(item)
        }

        let buttonItem = AlertButtonItem(
                tag: texts.count,
                title: "security_settings.delete_alert_button".localized,
                textStyle: ButtonTheme.whiteTextColorDictionary,
                backgroundStyle: ButtonTheme.redBackgroundDictionary
        ) { [weak self] in
            self?.delegate.didTapUnlink()
        }

        model.addItemView(buttonItem)
        self.buttonItem = buttonItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.actionSheetBackgroundColor
        contentBackgroundColor = .white
    }

    private func handleToggle(index: Int) {
        items[index].checked = !items[index].checked
        buttonItem?.isActive = items.filter { $0.checked == false }.isEmpty
        model.reload?()
    }

}

extension UnlinkViewController: IUnlinkView {

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}
