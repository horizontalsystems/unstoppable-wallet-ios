import UIKit
import SectionsTableView
import ThemeKit

class ManageAccountsViewController: ThemeViewController {
    private let delegate: IManageAccountsViewDelegate

    private let tableView = SectionsTableView(style: .grouped)
    private var viewItems = [ManageAccountViewItem]()

    init(delegate: IManageAccountsViewDelegate) {
        self.delegate = delegate

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "settings_manage_keys.title".localized
        navigationItem.backBarButtonItem = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)

        tableView.registerCell(forClass: TitleManageAccountCell.self)
        tableView.registerCell(forClass: ProceedManageAccountCell.self)

        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.viewDidLoad()
    }

    private func rows(viewItem: ManageAccountViewItem, index: Int) -> [RowProtocol] {
        var rows = [RowProtocol]()

        rows.append(
            Row<TitleManageAccountCell>(
                    id: "account_\(viewItem.title)",
                    autoDeselect: true,
                    dynamicHeight: { [weak self] _ in
                        TitleManageAccountCell.height(forContainerWidth: self?.tableView.width ?? 0, viewItem: viewItem)
                    },
                    bind: { [weak self] cell, _ in
                        let height = TitleManageAccountCell.height(forContainerWidth: self?.tableView.width ?? 0, viewItem: viewItem)
                        cell.bind(viewItem: viewItem, height: height)
                    }
            )
        )

        let states = [viewItem.topButtonState, viewItem.middleButtonState, viewItem.bottomButtonState].compactMap { $0 }
        rows.append(contentsOf: states.enumerated().map { stateIndex, state in
            let last = states.count - 1 == stateIndex

            return Row<ProceedManageAccountCell>(
                    id: "account_\(state.rawValue)",
                    autoDeselect: true,
                    dynamicHeight: { _ in
                        ProceedManageAccountCell.height
                    },
                    bind: { cell, _ in
                        cell.bind(state: state, highlighted: viewItem.highlighted, position: last ? .bottom : .inbetween)
                    },
                    action: { [weak self] _ in
                        self?.action(state: state, index: index)
                    }
            )
        })

        return rows
    }

    private func action(state: ManageAccountButtonState, index: Int) {
        switch state {
        case .create:
            delegate.didTapCreate(index: index)
        case .backup, .show:
            delegate.didTapBackup(index: index)
        case .restore:
            delegate.didTapRestore(index: index)
        case .delete:
            delegate.didTapUnlink(index: index)
        case .settings:
            delegate.didTapSettings(index: index)
        }
    }

}

extension ManageAccountsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        viewItems.enumerated().map { index, viewItem in
            Section(
                    id: "wallets",
                    headerState: .margin(height: .margin2x),
                    footerState: .margin(height: .margin1x),
                    rows: rows(viewItem: viewItem, index: index)
            )
        }
    }

}

extension ManageAccountsViewController: IManageAccountsView {

    func set(viewItems: [ManageAccountViewItem]) {
        self.viewItems = viewItems
        tableView.reload()
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.smartDescription)
    }

    func showSuccess() {
        HudHelper.instance.showSuccess()
    }

}
