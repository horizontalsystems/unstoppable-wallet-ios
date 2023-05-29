import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class CoinRankViewController: ThemeViewController {
    private let viewModel: CoinRankViewModel
    private let headerView: CoinRankHeaderView
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    private var viewItems: [CoinRankViewModel.ViewItem]?

    init(viewModel: CoinRankViewModel) {
        self.viewModel = viewModel
        headerView = CoinRankHeaderView(viewModel: viewModel)

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onTapClose))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.sectionDataSource = self

        tableView.registerCell(forClass: MarketHeaderCell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalTo(view.safeAreaLayoutGuide)
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(action: { [weak self] in self?.viewModel.onTapRetry() })

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }
        subscribe(disposeBag, viewModel.scrollToTopSignal) { [weak self] in self?.scrollToTop() }
    }

    @objc private func onTapClose() {
        dismiss(animated: true)
    }

    private func sync(viewItems: [CoinRankViewModel.ViewItem]?) {
        self.viewItems = viewItems

        tableView.isHidden = viewItems == nil
        tableView.reload()
    }

    private func scrollToTop() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }

}

extension CoinRankViewController: SectionsDataSource {

    private func row(viewItem: CoinRankViewModel.ViewItem, index: Int, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .text { component in
                        component.font = .captionSB
                        component.textColor = .themeGray
                        component.text = viewItem.rank
                        component.textAlignment = .center

                        component.snp.remakeConstraints { maker in
                            maker.width.equalTo(40)
                        }
                    },
                    .margin8,
                    .image32 { component in
                        component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: "placeholder_circle_32"))
                    },
                    .vStackCentered([
                        .textElement(text: .body(viewItem.code)),
                        .margin(1),
                        .textElement(text: .subhead2(viewItem.name)),
                    ]),
                    .textElement(text: .body(viewItem.value), parameters: .rightAlignment)
                ]),
                layoutMargins: UIEdgeInsets(top: 0, left: .margin8, bottom: 0, right: CellBuilderNew.defaultMargin),
                tableView: tableView,
                id: "row-\(index)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                },
                action: { [weak self] in
                    if let viewController = CoinPageModule.viewController(coinUid: viewItem.uid) {
                        self?.present(viewController, animated: true)
                    }
                }
        )
    }

    private func bind(cell: MarketHeaderCell) {
        cell.set(
                title: viewModel.title,
                description: viewModel.description,
                imageMode: .remote(imageUrl: viewModel.imageUid.headerImageUrl)
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItems else {
            return []
        }

        return [
            Section(
                    id: "header",
                    rows: [
                        Row<MarketHeaderCell>(
                                id: "header",
                                height: MarketHeaderCell.height,
                                bind: { [weak self] cell, _ in
                                    self?.bind(cell: cell)
                                }
                        )
                    ]
            ),
            Section(
                    id: "coins",
                    headerState: .static(view: headerView, height: CoinRankHeaderView.height),
                    footerState: .marginColor(height: .margin32, color: .clear),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isLast: index == viewItems.count - 1)
                    }
            )
        ]
    }

}
