import UIKit
import ActionSheet
import ThemeKit
import SectionsTableView

class UnlinkViewController: ThemeActionSheetController {
    private let delegate: IUnlinkViewDelegate

    private let tableView = SelfSizedSectionsTableView(style: .grouped)

    private var viewItems = [UnlinkModule.ViewItem]()
    private var accountTypeTitle: String?
    private var deleteButtonEnabled = false

    init(delegate: IUnlinkViewDelegate) {
        self.delegate = delegate
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: AlertTitleCell.self)
        tableView.registerCell(forClass: AlertCheckboxCell.self)
        tableView.registerCell(forClass: AlertRedButtonCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.alwaysBounceVertical = false

        delegate.onLoad()

        tableView.reload()
    }

    private var titleRow: RowProtocol {
        Row<AlertTitleCell>(
                id: "title",
                height: AlertTitleViewNew.height,
                bind: { [weak self] cell, _ in
                    cell.bind(
                            title: "settings_manage_keys.delete.title".localized,
                            subtitle: self?.accountTypeTitle,
                            image: UIImage(named: "Attention Icon")?.tinted(with: .themeLucian)
                    ) { [weak self] in
                        self?.delegate.onTapClose()
                    }
                }
        )
    }

    private var deleteButtonRow: RowProtocol {
        Row<AlertRedButtonCell>(
                id: "delete_button",
                height: AlertRedButtonCell.height,
                bind: { [unowned self] cell, _ in
                    cell.bind(
                            title: "security_settings.delete_alert_button".localized,
                            enabled: self.deleteButtonEnabled
                    ) { [weak self] in
                        self?.delegate.onTapDelete()
                    }
                }
        )
    }

    private func checkboxRow(viewItem: UnlinkModule.ViewItem, index: Int) -> RowProtocol {
        Row<AlertCheckboxCell>(
                id: "checkbox_\(index)",
                hash: "\(viewItem.checked)",
                height: 60,
                bind: { [weak self] cell, _ in
                    cell.bind(
                            text: self?.text(itemType: viewItem.type),
                            checked: viewItem.checked
                    )
                },
                action: { [weak self] _ in
                    self?.delegate.onTapViewItem(index: index)
                }
        )
    }

    private func text(itemType: UnlinkModule.ItemType) -> String {
        switch itemType {
        case .deleteAccount(let accountTypeTitle):
            return "settings_manage_keys.delete.confirmation_remove".localized(accountTypeTitle)
        case .disableCoins(let coinCodes):
            return "settings_manage_keys.delete.confirmation_disable".localized(coinCodes)
        case .loseAccess:
            return "settings_manage_keys.delete.confirmation_loose".localized
        }
    }

}

extension UnlinkViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var rows = [RowProtocol]()

        rows.append(titleRow)
        rows.append(contentsOf: viewItems.enumerated().map { checkboxRow(viewItem: $1, index: $0) })
        rows.append(deleteButtonRow)

        return [Section(id: "main", rows: rows)]
    }

}

extension UnlinkViewController: IUnlinkView {

    func set(accountTypeTitle: String) {
        self.accountTypeTitle = accountTypeTitle
    }

    func set(viewItems: [UnlinkModule.ViewItem], deleteButtonEnabled: Bool) {
        self.viewItems = viewItems
        self.deleteButtonEnabled = deleteButtonEnabled
        tableView.reload()
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}
