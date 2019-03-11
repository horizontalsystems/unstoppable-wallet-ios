import UIKit
import GrouviActionSheet

class AgreementViewController: ActionSheetController {
    private let delegate: IAgreementViewDelegate

    private var items = [ConfirmationCheckboxItem]()
    private var buttonItem: AlertButtonItem?

    init(delegate: IAgreementViewDelegate) {
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

        let confirm = "backup.confirmation.secret_key".localized
        let confirmAttributed = NSMutableAttributedString(string: confirm, attributes: [NSAttributedStringKey.foregroundColor: ConfirmationTheme.textColor, NSAttributedStringKey.font: UIFont.systemFont(ofSize: 17)])
        confirmAttributed.addAttribute(NSAttributedStringKey.font, value: ConfirmationTheme.regularFont, range: NSMakeRange(0, confirm.count))
        texts.append(confirmAttributed)
        texts.append(NSAttributedString(string: "backup.confirmation.secure".localized, attributes: [NSAttributedStringKey.foregroundColor: ConfirmationTheme.textColor, NSAttributedStringKey.font: ConfirmationTheme.regularFont]))

        for (index, text) in texts.enumerated() {
            let item = ConfirmationCheckboxItem(descriptionText: text, tag: index) { [weak self] view in
                self?.handleToggle(index: index)
            }

            model.addItemView(item)
            items.append(item)
        }

        let buttonItem = AlertButtonItem(
                tag: texts.count,
                title: "alert.confirm".localized,
                textStyle: ButtonTheme.textColorOnWhiteBackgroundDictionary,
                backgroundStyle: ButtonTheme.yellowBackgroundOnWhiteBackgroundDictionary
        ) { [weak self] in
            self?.delegate.didTapConfirm()
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

extension AgreementViewController: IAgreementView {
}
