import UIKit
import ActionSheet

struct AlertRow {
    let text: String
    let selected: Bool
}

class AlertViewController: WalletActionSheetController {
    static let sideMargin: CGFloat = 61

    private var items = [TextSelectItem]()
    private let onSelect: (Int) -> ()

    init(header: String? = nil, message: String? = nil, rows: [AlertRow], onSelect: @escaping (Int) -> ()) {
        self.onSelect = onSelect

        let config = ActionSheetThemeConfig(
                actionStyle: .alert,
                sideMargin: AlertViewController.sideMargin,
                cornerRadius: .margin4x,
                separatorColor: .themeSteel20,
                backgroundStyle: .color(color: .themeBlack50)
        )
        super.init(withModel: BaseAlertModel(), actionSheetThemeConfig: config)

        if let header = header {
            addHeader(text: header)
        }

        if let message = message {
            addMessage(text: message)
        }

        for (index, row) in rows.enumerated() {
            addRow(index: index, row: row)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSelected(index: Int) {
        items.forEach { $0.selected = false }
        items[index].selected = true
        model.reload?()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentBackgroundColor = .white
    }

    private func addHeader(text: String) {
        let item = TextSelectItem(
                text: text,
                font: .subhead1,
                color: .themeGray,
                height: 40,
                tag: -1
        )

        model.addItemView(item)
    }

    private func addMessage(text: String) {
        let item = MessageItem(
                text: text,
                font: .subhead1,
                color: .themeOz
        )

        model.addItemView(item)
    }

    private func addRow(index: Int, row: AlertRow) {
        let item = TextSelectItem(
                text: row.text,
                font: .headline2,
                color: .themeOz,
                height: 53,
                selected: row.selected,
                tag: index
        ) { [weak self] view in
            self?.onSelect(index)
            self?.dismiss(animated: true)
        }

        model.addItemView(item)
        items.append(item)
    }

}
