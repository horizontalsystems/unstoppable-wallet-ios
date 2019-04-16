import UIKit
import ActionSheet

class UnlinkViewController: ActionSheetController {
    private let delegate: IUnlinkViewDelegate
    private var items = [ConfirmationCheckboxItem]()
    private var buttonItem: AlertButtonItem?

    init(delegate: IUnlinkViewDelegate) {
        self.delegate = delegate
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.actionSheetBackgroundColor
        contentBackgroundColor = .white

        var texts = [NSAttributedString]()

        let attributes = [NSAttributedString.Key.foregroundColor: ConfirmationTheme.textColor, NSAttributedString.Key.font: ConfirmationTheme.regularFont]
        texts.append(NSAttributedString(string: "settings_security.import_wallet_confirmation_1".localized, attributes: attributes))
        texts.append(NSAttributedString(string: "settings_security.import_wallet_confirmation_2".localized, attributes: attributes))

        for (index, text) in texts.enumerated() {
            let item = ConfirmationCheckboxItem(descriptionText: text, tag: index) { [weak self] view in
                self?.handleToggle(index: index)
            }

            model.addItemView(item)
            items.append(item)
        }

        let buttonItem = AlertButtonItem(
                tag: texts.count,
                title: "security_settings.unlink_alert_button".localized,
                textStyle: ButtonTheme.whiteTextColorOnDarkBackgroundDictionary,
                backgroundStyle: ButtonTheme.redBackgroundOnWhiteBackgroundDictionary
        ) { [weak self] in
            self?.delegate.didTapUnlink()
        }

        model.addItemView(buttonItem)
        self.buttonItem = buttonItem
    }

    private func handleToggle(index: Int) {
        items[index].checked = !items[index].checked
        buttonItem?.isActive = items.filter { $0.checked == false }.isEmpty
        model.reload?()
    }

}

extension UnlinkViewController: IUnlinkView {
}
