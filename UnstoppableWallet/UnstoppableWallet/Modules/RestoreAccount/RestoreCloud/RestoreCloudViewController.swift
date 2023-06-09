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

    private var viewItem: RestoreCloudViewModel.ViewItem

    init(viewModel: RestoreCloudViewModel, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.returnViewController = returnViewController

        viewItem = viewModel.viewItem

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

        viewModel.$viewItem
                .receive(on: DispatchQueue.main)
                .sink { [weak self] viewItem in
                    self?.sync(viewItem: viewItem)
                }
                .store(in: &cancellables)

        viewModel.restorePublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.restore(item: $0)
                }.store(in: &cancellables)

        tableView.buildSections()
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc private func onCancel() {
        (returnViewController ?? self)?.dismiss(animated: true)
    }

    private func restore(item: RestoreCloudModule.RestoredBackup) {
        let viewController = RestoreCloudPassphraseModule.restorePassword(item: item, returnViewController: returnViewController)

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func sync(viewItem: RestoreCloudViewModel.ViewItem) {
        emptyView.isHidden = !viewItem.isEmpty
        tableView.reload()
    }

    private func row(viewItem: RestoreCloudViewModel.BackupViewItem, rowInfo: RowInfo) -> RowProtocol {
        tableView.universalRow62(
                id: viewItem.uniqueId,
                title: .body(viewItem.name),
                description: .subhead2(viewItem.description),
                accessoryType: .disclosure,
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
        guard !viewItem.isEmpty else {
            return []
        }

        var sections = [
            descriptionSection,
        ]
        if !viewItem.notImported.isEmpty {
            sections.append(
                    section(id: "not_imported", viewItems: viewModel.viewItem.notImported)
            )
        }

        if !viewItem.imported.isEmpty {
            sections.append(
                section(id: "imported", headerTitle: "restore.cloud.imported".localized, viewItems: viewModel.viewItem.imported)
            )
        }

        return sections
    }

}
