import UIKit
import RxSwift
import ThemeKit
import SectionsTableView
import ComponentKit
import HUD

class CoinReportsViewController: ThemeViewController {
    private let viewModel: CoinReportsViewModel
    private let urlManager: UrlManager
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .grouped)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    private var viewItems: [CoinReportsViewModel.ViewItem]?

    init(viewModel: CoinReportsViewModel, urlManager: UrlManager) {
        self.viewModel = viewModel
        self.urlManager = urlManager

        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "coin_page.reports".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: PostCell.self)

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
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(viewItems: [CoinReportsViewModel.ViewItem]?) {
        self.viewItems = viewItems

        if viewItems != nil {
            tableView.bounces = true
        } else {
            tableView.bounces = false
        }

        tableView.reload()
    }

}

extension CoinReportsViewController: SectionsDataSource {

    private func row(viewItem: CoinReportsViewModel.ViewItem) -> RowProtocol {
        Row<PostCell>(
                id: viewItem.title,
                height: PostCell.height,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .lawrence, isFirst: true, isLast: true)
                    cell.bind(
                            header: viewItem.author,
                            title: viewItem.title,
                            body: viewItem.body,
                            time: viewItem.date
                    )
                },
                action: { [weak self] _ in
                    self?.urlManager.open(url: viewItem.url, from: self)
                }
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItems = viewItems {
            for (index, viewItem) in viewItems.enumerated() {
                let section = Section(
                        id: "report\(index)",
                        headerState: .margin(height: .margin12),
                        footerState: .margin(height: index == viewItems.count - 1 ? .margin32 : 0),
                        rows: [
                            row(viewItem: viewItem)
                        ]
                )

                sections.append(section)
            }
        }

        return sections
    }

}
