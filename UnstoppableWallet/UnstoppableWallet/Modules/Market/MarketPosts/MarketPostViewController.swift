import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit

class MarketPostViewController: ThemeViewController {
    private let postViewModel: MarketPostViewModel
    private let urlManager: IUrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let refreshControl = UIRefreshControl()

    weak var parentNavigationController: UINavigationController?

    private var postState: MarketPostViewModel.State = .loading

    init(postViewModel: MarketPostViewModel, urlManager: IUrlManager) {
        self.postViewModel = postViewModel
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

        subscribe(disposeBag, postViewModel.stateDriver) { [weak self] state in
            self?.postState = state
            self?.tableView.reload()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.refreshControl = refreshControl
    }

    @objc func onRefresh() {
        refresh()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }

    private func row(viewItem: MarketPostViewModel.ViewItem) -> RowProtocol {
        Row<MarketPostCell>(
                id: viewItem.title,
                height: MarketPostCell.height,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.set(source: viewItem.source, title: viewItem.title, description: viewItem.body, date: viewItem.timestamp)
                },
                action: { [weak self] _ in
                    self?.onSelect(viewItem: viewItem)
                }
        )
    }

    private func onSelect(viewItem: MarketPostViewModel.ViewItem) {
        urlManager.open(url: viewItem.url, from: parentNavigationController)
    }

}

extension MarketPostViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        switch postState {
        case .loading:
            let row = Row<SpinnerCell>(
                    id: "post_spinner",
                    height: .heightCell48
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
        case .loaded(let postViewItems):
            guard !postViewItems.isEmpty else {
                return sections
            }

            sections.append(contentsOf:
            postViewItems.enumerated().map { (index, item) in Section(
                    id: "post_\(index)",
                    headerState: .margin(height: index == 0 ? .margin12 : 0),
                    footerState: .margin(height: .margin12),
                    rows: [row(viewItem: item)]
            )})
        }

        return sections
    }

    public func refresh() {
        postViewModel.refresh()
    }

}
