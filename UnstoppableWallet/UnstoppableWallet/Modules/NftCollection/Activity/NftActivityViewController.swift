import ComponentKit
import HUD
import RxCocoa
import RxSwift
import SectionsTableView
import SnapKit
import ThemeKit
import UIKit

class NftActivityViewController: ThemeViewController {
    private let viewModel: NftActivityViewModel
    private let cellFactory: INftActivityCellFactory
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let headerView: NftActivityHeaderView
    private let spinnerWrapper = UIView()
    private let spinner = HUDActivityView.create(with: .medium24)
    private let emptyView = PlaceholderView()
    private let errorView = PlaceholderViewModule.reachabilityView()

    weak var parentNavigationController: UINavigationController? {
        didSet {
            cellFactory.parentNavigationController = parentNavigationController
        }
    }

    private var viewItem: NftActivityViewModel.ViewItem?

    init(viewModel: NftActivityViewModel, cellFactory: INftActivityCellFactory) {
        self.viewModel = viewModel
        self.cellFactory = cellFactory
        headerView = NftActivityHeaderView(viewModel: viewModel)

        super.init()

        headerView.viewController = self
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(headerView)
        headerView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.height.equalTo(CGFloat.heightSingleLineCell)
        }

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        tableView.sectionHeaderTopPadding = 0
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: SpinnerCell.self)

        view.addSubview(spinnerWrapper)

        spinnerWrapper.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        spinnerWrapper.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.top.equalTo(headerView.snp.bottom)
            maker.leading.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.isHidden = true
        emptyView.image = UIImage(named: "outgoing_raw_48")
        emptyView.text = "nft.activity.empty_list".localized

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
        subscribe(disposeBag, viewModel.loadingDriver) { [weak self] loading in
            self?.spinner.isHidden = !loading
        }
        subscribe(disposeBag, viewModel.syncErrorDriver) { [weak self] visible in
            self?.errorView.isHidden = !visible
        }

        viewModel.onLoad()
    }

    @objc private func onRetry() {
        viewModel.onTapRetry()
    }

    private func sync(viewItem: NftActivityViewModel.ViewItem?) {
        self.viewItem = viewItem
        tableView.reload()
        spinnerWrapper.isHidden = viewItem != nil
        emptyView.isHidden = !(viewItem.map { $0.eventViewItems.isEmpty && $0.allLoaded } ?? false)
    }
}

extension NftActivityViewController: SectionsDataSource {
    private func row(eventViewItem viewItem: NftActivityViewModel.EventViewItem, index: Int, isLast: Bool) -> RowProtocol {
        cellFactory.row(tableView: tableView, viewItem: viewItem, index: index, onReachBottom: isLast ? { [weak self] in self?.viewModel.onReachBottom() } : nil)
    }

    private func spinnerRow() -> RowProtocol {
        Row<SpinnerCell>(
            id: "spinner",
            height: 24
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()
        var rows = [RowProtocol]()

        if let viewItem {
            rows = viewItem.eventViewItems.enumerated().map { index, eventViewItem in
                row(eventViewItem: eventViewItem, index: index, isLast: index == viewItem.eventViewItems.count - 1)
            }
        }

        let mainSection = Section(
            id: "main",
            footerState: .marginColor(height: .margin12, color: .clear),
            rows: rows
        )

        sections.append(mainSection)

        if let viewItem, !viewItem.allLoaded {
            let spinnerSection = Section(
                id: "spinner",
                footerState: .marginColor(height: .margin32, color: .clear),
                rows: [
                    spinnerRow(),
                ]
            )

            sections.append(spinnerSection)
        }

        return sections
    }
}
