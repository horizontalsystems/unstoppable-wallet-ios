import SnapKit
import ThemeKit
import SectionsTableView

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

        title = "settings.app_status".localized
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
        tableView.registerCell(forClass: D8Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.sectionDataSource = self

        headerCell.bind(
                image: UIImage(named: "App Icon"),
                title: "Unstoppable",
                subtitle: "app_status.version".localized(viewModel.version)
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
                                height: .heightSingleLineCell,
                                bind: { [weak self] cell, _ in
                                    cell.bind(
                                            title: "app_status.linked_wallets".localized,
                                            value: self.map { "\($0.viewModel.linkedWalletsCount)" }
                                    )
                                },
                                action: { [weak self] cell in

                                }
                        ),
                        Row<D1Cell>(
                                id: "version-history",
                                height: .heightSingleLineCell,
                                bind: { cell, _ in
                                    cell.bind(
                                            title: "app_status.version_history".localized,
                                            last: true
                                    )
                                },
                                action: { [weak self] cell in

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
                                height: .heightSingleLineCell,
                                bind: { cell, _ in
                                    let (statusTitle, statusColor): (String, UIColor) = {
                                        switch viewItem.status {
                                        case .syncing: return ("Syncing...", .themeGray)
                                        case .notSynced: return ("Not Synced", .themeLucian)
                                        case .synced: return ("Synced", .themeRemus)
                                        }
                                    }()

                                    cell.bind(
                                            title: viewItem.name,
                                            value: statusTitle,
                                            valueColor: statusColor
                                    )
                                },
                                action: { [weak self] cell in

                                }
                        )
                    }
            )
        ]
    }

}
