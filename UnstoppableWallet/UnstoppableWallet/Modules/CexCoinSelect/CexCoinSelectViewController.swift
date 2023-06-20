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
    private var viewItems = [CexCoinSelectViewModel.ViewItem]()

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

        title = "cex_coin_select.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancel))
        navigationItem.searchController?.searchBar.placeholder = "cex_coin_select.search_placeholder".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.sectionDataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        viewModel.$viewItems
                .receive(on: DispatchQueue.main)
                .sink { [weak self] viewItems in
                    self?.viewItems = viewItems
                    self?.tableView.reload()
                }
                .store(in: &cancellables)

        viewItems = viewModel.viewItems
        tableView.buildSections()
    }

    @objc func onTapCancel() {
        dismiss(animated: true)
    }

    override func onUpdate(filter: String?) {
        viewModel.onUpdate(filter: filter)
    }

    private func onSelect(cexAsset: CexAsset) {
        switch mode {
        case .deposit: () // todo
        case .withdraw: () // todo
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
                                    ])
                                ]),
                                tableView: tableView,
                                id: "cex-asset-\(index)",
                                height: .heightDoubleLineCell,
                                bind: { cell in
                                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                                },
                                action: { [weak self] in
                                    self?.onSelect(cexAsset: viewItem.cexAsset)
                                }
                        )
                    }
            )
        ]
    }

}
