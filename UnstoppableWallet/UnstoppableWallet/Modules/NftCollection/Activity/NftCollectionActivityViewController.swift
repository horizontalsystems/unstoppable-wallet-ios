import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView
import HUD

class NftCollectionActivityViewController: ThemeViewController {
    private let viewModel: NftCollectionActivityViewModel
    private let disposeBag = DisposeBag()

    private let tableView = SectionsTableView(style: .plain)
    private let headerView: DropdownFilterHeaderView
    private let wrapperView = UIView()
    private let spinner = HUDActivityView.create(with: .medium24)
    private let errorView = PlaceholderViewModule.reachabilityView()

    weak var parentNavigationController: UINavigationController?

    private var viewItem: NftCollectionActivityViewModel.ViewItem?

    init(viewModel: NftCollectionActivityViewModel) {
        self.viewModel = viewModel
        headerView = DropdownFilterHeaderView(viewModel: viewModel, hasTopSeparator: false)

        super.init()

        headerView.viewController = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
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

        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.sectionDataSource = self
        tableView.registerCell(forClass: SpinnerCell.self)

        subscribe(disposeBag, viewModel.viewItemDriver) { [weak self] in self?.sync(viewItem: $0) }
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

    private func sync(viewItem: NftCollectionActivityViewModel.ViewItem?) {
        self.viewItem = viewItem
        tableView.reload()
        wrapperView.isHidden = viewItem != nil
    }

    private func openAsset(viewItem: NftCollectionActivityViewModel.EventViewItem, imageRatio: CGFloat) {
        let module = NftAssetModule.viewController(collectionUid: viewItem.collectionUid, contractAddress: viewItem.contractAddress, tokenId: viewItem.tokenId, imageRatio: imageRatio)
        parentNavigationController?.pushViewController(module, animated: true)
    }

}

extension NftCollectionActivityViewController: SectionsDataSource {

    private func row(eventViewItem viewItem: NftCollectionActivityViewModel.EventViewItem, index: Int, isLast: Bool) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .multiText, .multiText],
                tableView: tableView,
                id: "event-\(index)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { [weak self] cell in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)

                    cell.bind(index: 0) { (component: ImageComponent) in
                        component.setImage(urlString: viewItem.imageUrl, placeholder: nil)
                        component.imageView.cornerRadius = .cornerRadius4
                        component.imageView.backgroundColor = .themeSteel20
                        component.imageView.contentMode = .scaleAspectFill
                    }

                    cell.bind(index: 1) { (component: MultiTextComponent) in
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = viewItem.type
                        component.subtitle.text = viewItem.date
                    }

                    cell.bind(index: 2) { (component: MultiTextComponent) in
                        component.titleSpacingView.isHidden = true
                        component.set(style: .m1)
                        component.title.set(style: .b2)
                        component.subtitle.set(style: .d1)

                        component.title.text = viewItem.coinPrice
                        component.title.textAlignment = .right
                        component.subtitle.text = viewItem.fiatPrice
                        component.subtitle.textAlignment = .right
                    }

                    if isLast {
                        self?.viewModel.onReachBottom()
                    }
                },
                actionWithCell: { [weak self] cell in
                    let component: ImageComponent? = cell.component(index: 0)
                    self?.openAsset(viewItem: viewItem, imageRatio: component?.imageRatio ?? 1)
                }
        )
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

        if let viewItem = viewItem {
            rows = viewItem.eventViewItems.enumerated().map { index, eventViewItem in
                row(eventViewItem: eventViewItem, index: index, isLast: index == viewItem.eventViewItems.count - 1)
            }
        }

        let mainSection = Section(
                id: "main",
                headerState: .static(view: headerView, height: .heightSingleLineCell),
                footerState: .marginColor(height: .margin12, color: .clear),
                rows: rows
        )

        sections.append(mainSection)

        if let viewItem = viewItem, !viewItem.allLoaded {
            let spinnerSection = Section(
                    id: "spinner",
                    footerState: .marginColor(height: .margin32, color: .clear),
                    rows: [
                        spinnerRow()
                    ]
            )

            sections.append(spinnerSection)
        }

        return sections
    }

}
