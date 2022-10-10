import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class CoinTreasuriesViewController: ThemeViewController {
    private let viewModel: CoinTreasuriesViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    private var viewItems: [CoinTreasuriesViewModel.ViewItem]?
    private let headerView: DropdownSortHeaderView

    init(viewModel: CoinTreasuriesViewModel) {
        self.viewModel = viewModel
        headerView = DropdownSortHeaderView(viewModel: viewModel)

        super.init()

        headerView.viewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_page.treasuries".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: BrandFooterCell.self)

        view.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }
        subscribe(disposeBag, viewModel.scrollToTopSignal) { [weak self] in self?.scrollToTop() }
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(viewItems: [CoinTreasuriesViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if viewItems != nil {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

    private func scrollToTop() {
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }

}

extension CoinTreasuriesViewController: SectionsDataSource {

    private func row(viewItem: CoinTreasuriesViewModel.ViewItem, index: Int, isLast: Bool) -> RowProtocol {
        CellBuilderNew.row(
                rootElement: .hStack([
                    .image24 { component in
                        component.setImage(urlString: viewItem.logoUrl, placeholder: UIImage(named: "icon_placeholder_24"))
                    },
                    .vStackCentered([
                        .hStack([
                            .text { component in
                                component.font = .body
                                component.textColor = .themeLeah
                                component.text = viewItem.fund
                            },
                            .text { component in
                                component.font = .body
                                component.textColor = .themeLeah
                                component.textAlignment = .right
                                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                                component.text = viewItem.amount
                            }
                        ]),
                        .margin(3),
                        .hStack([
                            .text { component in
                                component.font = .subhead2
                                component.textColor = .themeGray
                                component.text = viewItem.country
                            },
                            .text { component in
                                component.setContentCompressionResistancePriority(.required, for: .horizontal)
                                component.setContentHuggingPriority(.required, for: .horizontal)
                                component.textAlignment = .right
                                component.font = .subhead2
                                component.textColor = .themeJacob
                                component.text = viewItem.amountInCurrency
                            }
                        ])
                    ])
                ]),
                tableView: tableView,
                id: "treasury-\(index)",
                height: .heightDoubleLineCell,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                }
        )
    }

    private func poweredBySection(text: String) -> SectionProtocol {
        Section(
                id: "powered-by",
                rows: [
                    Row<BrandFooterCell>(
                            id: "powered-by",
                            dynamicHeight: { containerWidth in
                                BrandFooterCell.height(containerWidth: containerWidth, title: text)
                            },
                            bind: { cell, _ in
                                cell.title = text
                            }
                    )
                ]
        )
    }

    func buildSections() -> [SectionProtocol] {
        guard let viewItems = viewItems else {
            return []
        }

        return [
            Section(
                    id: "treasuries",
                    headerState: .static(view: headerView, height: .heightSingleLineCell),
                    footerState: .marginColor(height: .margin32, color: .clear),
                    rows: viewItems.enumerated().map { row(viewItem: $1, index: $0, isLast: $0 == viewItems.count - 1) }
            ),
            poweredBySection(text: "Powered by Bitcointreasuries.net")
        ]
    }

}
