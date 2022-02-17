import UIKit
import Foundation
import RxSwift
import RxCocoa
import ThemeKit
import ComponentKit
import SectionsTableView
import Kingfisher

class NftCollectionsViewController: ThemeViewController {
    private let viewModel: NftCollectionsViewModel
    private let headerView: NftCollectionsHeaderView
    private let disposeBag = DisposeBag()

    private var viewItems = [NftCollectionsViewModel.ViewItem]()
    private var expandedUids = Set<String>()

    private let tableView = SectionsTableView(style: .plain)

    private var loaded = false

    init(viewModel: NftCollectionsViewModel, headerViewModel: NftCollectionsHeaderViewModel) {
        self.viewModel = viewModel
        headerView = NftCollectionsHeaderView(viewModel: headerViewModel)

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "nft_collections.title".localized

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.registerCell(forClass: NftCollectionsDoubleCell.self)
        tableView.sectionDataSource = self

        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.expandedUidsDriver) { [weak self] in self?.sync(expandedUids: $0) }

        tableView.buildSections()
        loaded = true
    }

    private func sync(viewItems: [NftCollectionsViewModel.ViewItem]) {
        self.viewItems = viewItems

        if loaded {
            tableView.reload(animated: true)
        }
    }

    private func sync(expandedUids: Set<String>) {
        self.expandedUids = expandedUids

        if loaded {
            tableView.reload(animated: true)
        }
    }

    private func openAsset(viewItem: NftCollectionsViewModel.AssetViewItem, imageRatio: CGFloat) {
        guard let module = NftAssetModule.viewController(collectionUid: viewItem.collectionUid, tokenId: viewItem.tokenId, imageRatio: imageRatio) else {
            return
        }

        present(module, animated: true)
    }

}

extension NftCollectionsViewController: SectionsDataSource {

    private func row(leftViewItem: NftCollectionsViewModel.AssetViewItem, rightViewItem: NftCollectionsViewModel.AssetViewItem?, isLast: Bool) -> RowProtocol {
        Row<NftCollectionsDoubleCell>(
                id: "token-\(leftViewItem.uid)-\(rightViewItem?.uid ?? "nil")",
                hash: "\(leftViewItem.hash)-\(rightViewItem?.hash ?? "nil")",
                dynamicHeight: { width in
                    NftCollectionsDoubleCell.height(containerWidth: width, isLast: isLast)
                },
                bind: { cell, _ in
                    cell.bind(leftViewItem: leftViewItem, rightViewItem: rightViewItem) { [weak self] viewItem, imageRatio in
                        self?.openAsset(viewItem: viewItem, imageRatio: imageRatio)
                    }
                }
        )
    }

    private func row(viewItem: NftCollectionsViewModel.ViewItem, expanded: Bool, index: Int) -> RowProtocol {
        CellBuilder.selectableRow(
                elements: [.image24, .text, .text, .margin8, .image20],
                tableView: tableView,
                id: "collection-\(viewItem.uid)",
                hash: "\(viewItem.count)-\(expanded)",
                height: .heightCell48,
                bind: { cell in
                    cell.set(backgroundStyle: .transparent)
                    cell.wrapperView.backgroundColor = .themeTyler
                    cell.selectionStyle = .none

                    cell.bind(index: 0, block: { (component: ImageComponent) in
                        component.imageView.kf.setImage(with: viewItem.imageUrl.flatMap { URL(string: $0) })
                        component.imageView.cornerRadius = .cornerRadius4
                        component.imageView.backgroundColor = .themeSteel20
                    })
                    cell.bind(index: 1, block: { (component: TextComponent) in
                        component.set(style: .a2)
                        component.text = viewItem.name
                    })
                    cell.bind(index: 2, block: { (component: TextComponent) in
                        component.set(style: .c1)
                        component.text = viewItem.count
                        component.setContentHuggingPriority(.required, for: .horizontal)
                        component.setContentCompressionResistancePriority(.required, for: .horizontal)
                    })
                    cell.bind(index: 3, block: { (component: ImageComponent) in
                        component.imageView.image = UIImage(named: expanded ? "arrow_big_up_20" : "arrow_big_down_20")?.withTintColor(.themeGray)
                    })
                },
                action: { [weak self] in
                    self?.viewModel.onTap(uid: viewItem.uid)
                }
        )
    }

    func rows(viewItems: [NftCollectionsViewModel.ViewItem]) -> [RowProtocol] {
        var rows = [RowProtocol]()

        for (index, viewItem) in viewItems.enumerated() {
            let expanded = expandedUids.contains(viewItem.uid)

            rows.append(row(viewItem: viewItem, expanded: expanded, index: index))

            if expanded {
                let doubleRowCount = viewItem.assetViewItems.count / 2
                let hasSingleRow = viewItem.assetViewItems.count % 2 == 1

                for i in 0..<doubleRowCount {
                    let row = row(
                            leftViewItem: viewItem.assetViewItems[i * 2],
                            rightViewItem: viewItem.assetViewItems[(i * 2) + 1],
                            isLast: i == doubleRowCount - 1 && !hasSingleRow
                    )
                    rows.append(row)
                }

                if let assetViewItem = viewItem.assetViewItems.last, hasSingleRow {
                    let row = row(
                            leftViewItem: assetViewItem,
                            rightViewItem: nil,
                            isLast: true
                    )
                    rows.append(row)
                }
            }
        }

        return rows
    }

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "main",
                    headerState: .static(view: headerView, height: .heightCell48),
                    footerState: .marginColor(height: .margin32, color: .clear),
                    rows: rows(viewItems: viewItems)
            )
        ]
    }

}
