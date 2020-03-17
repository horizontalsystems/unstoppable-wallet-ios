import UIKit
import SectionsTableView
import ThemeKit

class BlockchainSettingsListViewController: ThemeViewController {
    private let delegate: IBlockchainSettingsListViewDelegate

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems = [BlockchainSettingsListViewItem]()

    init(delegate: IBlockchainSettingsListViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_settings.title".localized

        tableView.registerCell(forClass: BlockchainSettingsListCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.onLoad()
        tableView.buildSections()
    }

    private func rows() -> [RowProtocol] {
        let itemsCount = viewItems.count

        return viewItems.enumerated().map { index, item in
            Row<BlockchainSettingsListCell>(
                    id: item.title,
                    hash: item.subtitle,
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { cell, _ in
                        cell.bind(item: item, last: index == itemsCount - 1)
                    },
                    action: { [weak self] _ in
                        if item.enabled {
                            self?.handleSelect(index: index)
                        }
                    }
            )
        }
    }

    @objc private func onTapRightBarButton() {
        delegate.onConfirm()
    }

    private func handleSelect(index: Int) {
        delegate.onSelect(index: index)
    }

}

extension BlockchainSettingsListViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        sections.append(Section(
                id: "sync_mode",
                headerState: .margin(height: .margin3x),
                rows: rows()
        ))

        return sections
    }

}

extension BlockchainSettingsListViewController: IBlockchainSettingsListView {

    func showNextButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.next".localized, style: .plain, target: self, action: #selector(onTapRightBarButton))
    }

    func showRestoreButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(onTapRightBarButton))
    }

    func showDoneButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapRightBarButton))
    }

    func set(viewItems: [BlockchainSettingsListViewItem]) {
        self.viewItems = viewItems
        tableView.reload(animated: true)
    }

}
