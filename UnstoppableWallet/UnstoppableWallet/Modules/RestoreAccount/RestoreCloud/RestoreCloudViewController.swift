import Combine
import Foundation
import UIKit
import ComponentKit
import SectionsTableView
import ThemeKit

class RestoreCloudViewController: ThemeViewController {
    private let viewModel: RestoreCloudViewModel
    private var cancellables = Set<AnyCancellable>()

    private weak var returnViewController: UIViewController?

    private let emptyView = PlaceholderView()
    private let tableView = SectionsTableView(style: .grouped)

    private var walletViewItem: RestoreCloudViewModel.ViewItem
    private var fullBackupViewItem: RestoreCloudViewModel.ViewItem

    init(viewModel: RestoreCloudViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        walletViewItem = viewModel.walletViewItem
        fullBackupViewItem = viewModel.fullBackupViewItem

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "restore.cloud.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.image = UIImage(named: "no_internet_48")
        emptyView.text = "restore.cloud.empty".localized

        viewModel.$walletViewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] viewItem in
                    self?.sync(type: .wallet, viewItem: viewItem)
                }
                .store(in: &cancellables)

        viewModel.$fullBackupViewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] viewItem in
                    self?.sync(type: .full, viewItem: viewItem)
                }
                .store(in: &cancellables)

        viewModel.restorePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.restore(item: $0)
                }.store(in: &cancellables)

        viewModel.deleteItemCompletedPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.deleteBackupCompleted(successful: $0)
                }.store(in: &cancellables)

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onCancel() {
        (returnViewController ?? self)?.dismiss(animated: true)
    }

    private func restore(item: BackupModule.NamedSource) {
        let viewController = RestorePassphraseModule.viewController(item: item, returnViewController: returnViewController)

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func deleteBackupCompleted(successful: Bool) {
        if successful {
            HudHelper.instance.show(banner: .deleted)
        } else {
            HudHelper.instance.show(banner: .error(string: "backup.cloud.cant_delete_file".localized))
        }
    }

    private func sync(type: RestoreCloudViewModel.BackupType, viewItem: RestoreCloudViewModel.ViewItem) {
        switch type {
        case .wallet: walletViewItem = viewItem
        case .full: fullBackupViewItem = viewItem
        }

        emptyView.isHidden = !walletViewItem.isEmpty || !fullBackupViewItem.isEmpty
        tableView.reload()
    }

    private func deleteRowAction(id: String) -> RowAction {
        RowAction(pattern: .icon(
                image: UIImage(named: "circle_minus_shifted_24"),
                background: UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ), action: { [weak self] cell in
            self?.viewModel.remove(id: id)
        })
    }

    private func row(viewItem: RestoreCloudViewModel.BackupViewItem, rowInfo: RowInfo) -> RowProtocol {
        let rowAction = deleteRowAction(id: viewItem.uniqueId)

        return tableView.universalRow62(
                id: viewItem.uniqueId,
                title: .body(viewItem.name),
                description: .subhead2(viewItem.description),
                accessoryType: .disclosure,
                rowActionProvider: { [ rowAction ] },
                isFirst: rowInfo.isFirst,
                isLast: rowInfo.isLast
        ) { [weak self] in
            self?.viewModel.didTap(id: viewItem.uniqueId)
        }
    }

    private func section(id: String, headerTitle: String? = nil, viewItems: [RestoreCloudViewModel.BackupViewItem]) -> SectionProtocol {
        let title = headerTitle ?? ""
        return Section(id: id,
                headerState: title.isEmpty ? .margin(height: 0) : tableView.sectionHeader(text: title),
                footerState: .margin(height: 24),
                rows: viewItems.enumerated().map { index, viewItem in row(viewItem: viewItem, rowInfo: RowInfo(index: index, count: viewItems.count)) }
        )
    }

    private var descriptionSection: SectionProtocol {
        Section(
                id: "description",
                headerState: .margin(height: .margin12),
                footerState: .margin(height: .margin32),
                rows: [
                    tableView.descriptionRow(
                            id: "description",
                            text: "restore.cloud.description".localized,
                            font: .subhead2,
                            textColor: .themeGray,
                            ignoreBottomMargin: true
                    )
                ]
        )
    }

}

extension RestoreCloudViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        guard !walletViewItem.isEmpty || !fullBackupViewItem.isEmpty else {
            return []
        }

        var sections = [ descriptionSection ]

        if !walletViewItem.notImported.isEmpty {
            sections.append(
                    section(id: "not_imported", headerTitle: "restore.cloud.wallets".localized, viewItems: viewModel.walletViewItem.notImported)
            )
        }

        if !walletViewItem.imported.isEmpty {
            sections.append(
                section(id: "imported", headerTitle: "restore.cloud.imported".localized, viewItems: viewModel.walletViewItem.imported)
            )
        }

        if !fullBackupViewItem.notImported.isEmpty {
            sections.append(
                section(id: "app_backups", headerTitle: "restore.cloud.app_backups".localized, viewItems: viewModel.fullBackupViewItem.notImported)
            )
        }

        return sections
    }

}
