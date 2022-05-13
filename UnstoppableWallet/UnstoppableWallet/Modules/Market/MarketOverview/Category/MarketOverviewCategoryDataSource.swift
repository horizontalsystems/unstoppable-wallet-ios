import UIKit
import RxSwift
import RxCocoa
import SectionsTableView

class MarketOverviewCategoryDataSource {
    private let disposeBag = DisposeBag()

    private let viewModel: MarketOverviewCategoryViewModel
    var presentDelegate: IPresentDelegate

    private let categoryCell = MarketOverviewCategoryCell()

    init(viewModel: MarketOverviewCategoryViewModel, presentDelegate: IPresentDelegate) {
        self.viewModel = viewModel
        self.presentDelegate = presentDelegate

        categoryCell.onSelect = { [weak self] index in
            guard let viewItem = self?.viewModel.viewItem?.viewItems[index], let viewController = MarketCategoryModule.viewController(categoryUid: viewItem.uid) else {
                return
            }
            self?.presentDelegate.present(viewController: viewController)
        }
    }

    private func onSelect(listViewItem: MarketModule.ListViewItem) {
        guard let uid = listViewItem.uid, let module = CoinPageModule.viewController(coinUid: uid) else {
            return
        }

        presentDelegate.present(viewController: module)
    }

}

extension MarketOverviewCategoryDataSource: IMarketOverviewDataSource {

    func sections(tableView: UITableView) -> [SectionProtocol] {
        categoryCell.viewItems = viewModel.viewItem?.viewItems ?? []

        var sections = [SectionProtocol]()
        if let viewItem = viewModel.viewItem {
            let headerSection = Section(
                    id: "categories_header",
                    footerState: .margin(height: .margin12),
                    rows: [
                        Row<MarketOverviewHeaderCell>(
                                id: "categories_header_cell",
                                height: .heightCell48,
                                bind: { [weak self] cell, _ in
                                    cell.set(backgroundStyle: .transparent)

                                    cell.buttonMode = .seeAll
                                    cell.onSeeAll = {
                                        self?.presentDelegate.push(viewController: MarketDiscoveryModule.viewController())
                                    }

                                    cell.titleImage = UIImage(named: viewItem.imageName)
                                    cell.title = viewItem.title
                                }
                        )
                    ]
            )

            let categorySection = Section(
                    id: "categories",
                    rows: [
                        StaticRow(
                                cell: categoryCell,
                                id: "metrics",
                                height: MarketOverviewCategoryCell.cellHeight
                        )
                    ]
            )

            sections.append(headerSection)
            sections.append(categorySection)
        }

        return sections
    }

}
