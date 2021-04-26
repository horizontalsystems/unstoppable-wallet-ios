import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit

class AppStatusViewControllerNew: ThemeViewController {
    private let viewModel: AppStatusViewModel

    private let tableView = SectionsTableView(style: .grouped)
    private let headerCell = TermsHeaderCell()

    init(viewModel: AppStatusViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "app_status.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.share".localized, style: .plain, target: self, action: #selector(onTapShare))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: TermsHeaderCell.self)
        tableView.registerCell(forClass: D1Cell.self)
        tableView.registerCell(forClass: D2Cell.self)
        tableView.registerCell(forClass: D11Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        headerCell.bind(
                image: UIImage(named: "App Icon"),
                title: "Unstoppable",
                subtitle: "version".localized(viewModel.version)
        )

        tableView.buildSections()
    }

    @objc private func onTapShare() {

    }

    private func header(text: String) -> ViewState<SubtitleHeaderFooterView> {
        .cellType(
                hash: text,
                binder: { view in
                    view.bind(text: text)
                },
                dynamicHeight: { _ in
                    SubtitleHeaderFooterView.height
                }
        )
    }

}

extension AppStatusViewControllerNew: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    footerState: .margin(height: .margin4x),
                    rows: [
                        StaticRow(cell: headerCell, id: "header", height: TermsHeaderCell.height)
                    ]
            ),
            Section(
                    id: "app-status",
                    headerState: header(text: "app_status.application_status".localized),
                    footerState: .margin(height: .margin8x),
                    rows: [
                        Row<D2Cell>(
                                id: "linked-wallets",
                                height: .heightCell48,
                                bind: { [weak self] cell, _ in
                                    cell.set(backgroundStyle: .lawrence)
                                    cell.title = "app_status.linked_wallets".localized
                                    cell.value = self.map { "\($0.viewModel.linkedWalletsCount)" }
                                    cell.valueColor = .themeLeah
                                },
                                action: { cell in

                                }
                        ),
                        Row<D1Cell>(
                                id: "version-history",
                                height: .heightCell48,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence, isLast: true)
                                    cell.title = "app_status.version_history".localized
                                },
                                action: { cell in

                                }
                        )
                    ]
            ),
            Section(
                    id: "blockchain-status",
                    headerState: header(text: "app_status.blockchain_status".localized),
                    footerState: .margin(height: .margin8x),
                    rows: viewModel.blockchainViewItems.enumerated().map { index, viewItem in
                        Row<D2Cell>(
                                id: "blockchain-\(index)",
                                height: .heightCell48,
                                bind: { cell, _ in
                                    cell.set(backgroundStyle: .lawrence) // todo: show bottom separator for last item
                                    cell.title = viewItem.name

                                    switch viewItem.status {
                                    case .syncing:
                                        cell.value = "Syncing..."
                                        cell.valueColor = .themeGray
                                    case .notSynced:
                                        cell.value = "Not Synced"
                                        cell.valueColor = .themeLucian
                                    case .synced:
                                        cell.value = "Synced"
                                        cell.valueColor = .themeRemus
                                    }
                                },
                                action: { cell in

                                }
                        )
                    }
            )
        ]
    }

}
