import UIKit
import GrouviActionSheet

class BaseConfirmationViewController: ActionSheetController {
    private let onConfirm: () -> ()
    private var items = [ConfirmationCheckboxItem]()

    var texts: [NSAttributedString] {
        fatalError()
    }

    func buttonItem(onTap: @escaping () -> ()) -> BaseButtonItem {
        fatalError()
    }

    init(onConfirm: @escaping () -> ()) {
        self.onConfirm = onConfirm
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: AppTheme.actionSheetConfig)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        backgroundColor = AppTheme.actionSheetBackgroundColor
        contentBackgroundColor = .white

        let buttonItem = self.buttonItem(onTap: {[weak self] in
            self?.dismiss(animated: true) {
                self?.onConfirm()
            }
        })

        texts.enumerated().forEach { index, string in
            let item = ConfirmationCheckboxItem(descriptionText: string, tag: index, required: true) { [weak self] view in
                if let view = view as? ConfirmationCheckboxView, let item = view.item {
                    item.checked = !item.checked
                    buttonItem.isActive = (self?.items.filter { $0.checked == false })?.isEmpty ?? false
                    self?.model.reload?()
                }
            }

            item.showSeparator = false
            item.height =  ConfirmationCheckboxItem.height(for: string)

            model.addItemView(item)
            items.append(item)
        }

        model.addItemView(buttonItem)
    }

}
