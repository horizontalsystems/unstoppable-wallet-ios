import UIKit
import ActionSheet
import ThemeKit

class UnlinkViewController: WalletActionSheetController {
    private let delegate: IUnlinkViewDelegate
    private var items = [ConfirmationCheckboxItem]()
    private var buttonItem: AlertButtonItem?

    init(delegate: IUnlinkViewDelegate) {
        self.delegate = delegate
        super.init()

        initItems()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func initItems() {
        let titleItem = AlertTitleItem(
                title: "settings_manage_keys.delete.title".localized,
                subtitle: delegate.title,
                icon: UIImage(named: "Attention Icon")?.withRenderingMode(.alwaysTemplate),
                iconTintColor: .themeLucian,
                tag: 0,
                onClose: { [weak self] in
                    self?.dismiss(byFade: false)
                }
        )
        model.addItemView(titleItem)

        var texts = [NSAttributedString]()

        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.themeOz, NSAttributedString.Key.font: UIFont.subhead2]
        texts.append(NSAttributedString(string: "settings_manage_keys.delete.confirmation_remove".localized(delegate.title), attributes: attributes))
        texts.append(NSAttributedString(string: "settings_manage_keys.delete.confirmation_disable".localized(delegate.coinCodes), attributes: attributes))
        texts.append(NSAttributedString(string: "settings_manage_keys.delete.confirmation_loose".localized(delegate.title), attributes: attributes))

        for (index, text) in texts.enumerated() {
            let item = ConfirmationCheckboxItem(descriptionText: text, tag: index + 1) { [weak self] view in
                self?.handleToggle(index: index)
            }

            model.addItemView(item)
            items.append(item)
        }

        let buttonItem = AlertButtonItem(
                tag: texts.count + 1,
                title: "security_settings.delete_alert_button".localized,
                createButton: { .appRed }
        ) { [weak self] in
            self?.delegate.didTapUnlink()
        }

        model.addItemView(buttonItem)
        self.buttonItem = buttonItem
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentBackgroundColor = .white
    }

    private func handleToggle(index: Int) {
        items[index].checked = !items[index].checked
        buttonItem?.isEnabled = items.filter { $0.checked == false }.isEmpty
        model.reload?()
    }

}

extension UnlinkViewController: IUnlinkView {

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}
