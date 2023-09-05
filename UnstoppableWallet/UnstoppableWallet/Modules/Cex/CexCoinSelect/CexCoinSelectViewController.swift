import Combine
import UIKit
import SnapKit
import ThemeKit
import ComponentKit
import SectionsTableView

class CexCoinSelectViewController: ThemeSearchViewController {
    private let viewModel: CexCoinSelectViewModel
    private let mode: CexCoinSelectModule.Mode
    private var cancellables = Set<AnyCancellable>()

    private let tableView = SectionsTableView(style: .grouped)
    private let notFoundPlaceholder = PlaceholderView(layoutType: .keyboard)

    private var viewItems = [CexCoinSelectViewModel.ViewItem]()
    private var isLoaded = false

    init(viewModel: CexCoinSelectViewModel, mode: CexCoinSelectModule.Mode) {
        self.viewModel = viewModel
        self.mode = mode

        super.init(scrollViews: [tableView])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        switch mode {
        case .deposit: title = "cex_coin_select.title".localized
        case .withdraw: title = "cex_coin_select.withdraw".localized
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        $filter
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in self?.viewModel.onUpdate(filter: $0) }
                .store(in: &cancellables)

        if viewModel.isEmpty {
            navigationItem.searchController = nil

            let emptyView = PlaceholderView()

            view.addSubview(emptyView)
            emptyView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }

            emptyView.image = UIImage(named: "empty_wallet_48")?.withTintColor(.themeGray)
            emptyView.text = "cex_coin_select.withdraw.empty".localized
        } else {
            navigationItem.searchController?.searchBar.placeholder = "cex_coin_select.search_placeholder".localized

            view.addSubview(tableView)
            tableView.snp.makeConstraints { maker in
                maker.edges.equalToSuperview()
            }

            tableView.sectionDataSource = self
            tableView.backgroundColor = .clear
            tableView.separatorStyle = .none

            view.addSubview(notFoundPlaceholder)
            notFoundPlaceholder.snp.makeConstraints { maker in
                maker.edges.equalTo(view.safeAreaLayoutGuide)
            }

            notFoundPlaceholder.image = UIImage(named: "not_found_48")
            notFoundPlaceholder.text = "no_results_found".localized

            viewModel.$viewItems
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] in self?.sync(viewItems: $0) }
                    .store(in: &cancellables)

            sync(viewItems: viewModel.viewItems)
        }

        isLoaded = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.deselectCell(withCoordinator: transitionCoordinator, animated: animated)
    }

    @objc func onTapCancel() {
        dismiss(animated: true)
    }

    private func sync(viewItems: [CexCoinSelectViewModel.ViewItem]) {
        self.viewItems = viewItems

        if viewItems.isEmpty {
            tableView.isHidden = true
            notFoundPlaceholder.isHidden = false
        } else {
            tableView.isHidden = false
            notFoundPlaceholder.isHidden = true
        }

        if isLoaded {
            tableView.reload()
        } else {
            tableView.buildSections()
        }
    }

    private func onSelect(cexAsset: CexAsset) {
        switch mode {
        case .deposit:
            guard let viewController = CexDepositModule.viewController(cexAsset: cexAsset) else {
                return
            }
            navigationController?.pushViewController(viewController, animated: true)
        case .withdraw:
            if let viewController = CexWithdrawModule.viewController(cexAsset: cexAsset) {
                navigationController?.pushViewController(viewController, animated: true)
            }
        }
    }

}

extension CexCoinSelectViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "cex-assets",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        let isLast = index == viewItems.count - 1

                        return CellBuilderNew.row(
                                rootElement: .hStack([
                                    .image32 { component in
                                        component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: "placeholder_circle_32"))
                                    },
                                    .vStackCentered([
                                        .textElement(text: .body(viewItem.title)),
                                        .margin(1),
                                        .textElement(text: .subhead2(viewItem.subtitle)),
                                    ]),
                                    .badge { component in
                                        component.isHidden = viewItem.enabled
                                        component.badgeView.set(style: .small)
                                        component.badgeView.text = "cex_coin_select.suspended".localized.uppercased()
                                    }
                                ]),
                                tableView: tableView,
                                id: "cex-asset-\(index)",
                                height: .heightDoubleLineCell,
                                bind: { cell in
                                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                                },
                                action: viewItem.enabled ? { [weak self] in
                                    self?.onSelect(cexAsset: viewItem.cexAsset)
                                } : nil
                        )
                    }
            )
        ]
    }

}
