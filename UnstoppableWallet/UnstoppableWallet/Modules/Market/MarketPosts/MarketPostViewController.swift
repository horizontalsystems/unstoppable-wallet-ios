import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit

class MarketPostViewController: ThemeViewController {
    private let viewModel: MarketPostViewModel
    private let urlManager: IUrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let refreshControl = UIRefreshControl()

    weak var parentNavigationController: UINavigationController?

    private var state: MarketPostViewModel.State = .loading

    init(viewModel: MarketPostViewModel, urlManager: IUrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl.tintColor = .themeLeah
        refreshControl.alpha = 0.6
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: SpinnerCell.self)
        tableView.registerCell(forClass: ErrorCell.self)
        tableView.registerCell(forClass: MarketPostCell.self)

        subscribe(disposeBag, viewModel.stateDriver) { [weak self] state in
            self?.state = state
            self?.tableView.reload()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    @objc func onRefresh() {
        viewModel.refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func open(url: String) {
        urlManager.open(url: url, from: parentNavigationController)
    }

}

extension MarketPostViewController: SectionsDataSource {

    private func row(viewItem: MarketPostViewModel.ViewItem) -> RowProtocol {
        Row<MarketPostCell>(
                id: viewItem.title,
                height: MarketPostCell.height,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.bind(viewItem: viewItem)
                },
                action: { [weak self] _ in
                    self?.open(url: viewItem.url)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        switch state {
        case .loading:
            let row = Row<SpinnerCell>(
                    id: "post_spinner",
                    dynamicHeight: { [weak self] _ in
                        max(0, (self?.tableView.height ?? 0))
                    }
            )

            sections.append(Section(id: "post_spinner", rows: [row]))
        case .error(let errorDescription):
            let row = Row<ErrorCell>(
                    id: "error",
                    dynamicHeight: { [weak self] _ in
                        max(0, (self?.tableView.height ?? 0))
                    },
                    bind: { cell, _ in
                        cell.errorText = errorDescription
                    }
            )

            sections.append(Section(id: "post_error", rows: [row]))
        case .loaded(let viewItems):
            for (index, viewItem) in viewItems.enumerated() {
                let section = Section(
                        id: "post_\(index)",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: index == viewItems.count - 1 ? .margin32 : 0),
                        rows: [row(viewItem: viewItem)]
                )

                sections.append(section)
            }
        }

        return sections
    }

}
