import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class NftCollectionAssetsViewController: ThemeViewController {
    private let viewModel: NftCollectionAssetsViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    weak var parentNavigationController: UINavigationController?

    private var viewItem: NftCollectionAssetsViewModel.ViewItem?

    init(viewModel: NftCollectionAssetsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let wrapperView = UIView()

        view.addSubview(wrapperView)
        wrapperView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide)
        }

        wrapperView.addSubview(spinner)
        spinner.snp.makeConstraints { maker in
            maker.center.equalToSuperview()
        }

        spinner.startAnimating()

        wrapperView.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        errorView.configureSyncError(action: { [weak self] in self?.onRetry() })

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: NftDoubleCell.self)
        tableView.registerCell(forClass: SpinnerCell.self)

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

    private func sync(viewItem: NftCollectionAssetsViewModel.ViewItem?) {
        self.viewItem = viewItem

        if viewItem != nil {
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
        }

        tableView.reload()
    }

    private func reloadTable() {
        tableView.buildSections()

        tableView.beginUpdates()
        tableView.endUpdates()
    }

    private func openAsset(viewItem: NftDoubleCell.ViewItem) {
        guard let providerCollectionUid = viewItem.providerCollectionUid else {
            return
        }

        let module = NftAssetModule.viewController(providerCollectionUid: providerCollectionUid, nftUid: viewItem.nftUid)
        parentNavigationController?.pushViewController(module, animated: true)
    }

}

extension NftCollectionAssetsViewController: SectionsDataSource {

    private func row(leftViewItem: NftDoubleCell.ViewItem, rightViewItem: NftDoubleCell.ViewItem?, isLast: Bool) -> RowProtocol {
        Row<NftDoubleCell>(
                id: "token-\(leftViewItem.nftUid.uid)-\(rightViewItem?.nftUid.uid ?? "nil")",
                hash: "\(leftViewItem.hash)-\(rightViewItem?.hash ?? "nil")",
                dynamicHeight: { width in
                    NftDoubleCell.height(containerWidth: width, isLast: isLast)
                },
                bind: { [weak self] cell, _ in
                    cell.bind(leftViewItem: leftViewItem, rightViewItem: rightViewItem) { [weak self] viewItem in
                        self?.openAsset(viewItem: viewItem)
                    }

                    if isLast {
                        self?.viewModel.onReachBottom()
                    }
                }
        )
    }

    private func rows(assetViewItems: [NftDoubleCell.ViewItem]) -> [RowProtocol] {
        var rows = [RowProtocol]()

        let doubleRowCount = assetViewItems.count / 2
        let hasSingleRow = assetViewItems.count % 2 == 1

        for i in 0..<doubleRowCount {
            let row = row(
                    leftViewItem: assetViewItems[i * 2],
                    rightViewItem: assetViewItems[(i * 2) + 1],
                    isLast: i == doubleRowCount - 1 && !hasSingleRow
            )
            rows.append(row)
        }

        if let assetViewItem = assetViewItems.last, hasSingleRow {
            let row = row(
                    leftViewItem: assetViewItem,
                    rightViewItem: nil,
                    isLast: true
            )
            rows.append(row)
        }

        return rows
    }

    private func spinnerRow() -> RowProtocol {
        Row<SpinnerCell>(
                id: "spinner",
                height: 24
        )
    }

    func buildSections() -> [SectionProtocol] {
        var sections = [SectionProtocol]()

        if let viewItem = viewItem {
            let assetsSection = Section(
                    id: "main",
                    rows: rows(assetViewItems: viewItem.assetViewItems)
            )

            sections.append(assetsSection)

            if !viewItem.allLoaded {
                let spinnerSection = Section(
                        id: "spinner",
                        footerState: .marginColor(height: .margin32, color: .clear),
                        rows: [
                            spinnerRow()
                        ]
                )

                sections.append(spinnerSection)
            }
        }

        return sections
    }

}
