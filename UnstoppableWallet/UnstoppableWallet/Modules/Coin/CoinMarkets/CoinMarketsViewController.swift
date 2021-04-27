import ThemeKit
import SnapKit
import SectionsTableView
import ComponentKit

class CoinMarketsViewController: ThemeViewController {
    private let viewModel: CoinMarketsViewModel

    private let tableView = SectionsTableView(style: .grouped)

    init(viewModel: CoinMarketsViewModel) {
        self.viewModel = viewModel

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        title = viewModel.title

        tableView.sectionDataSource = self

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.allowsSelection = false

        tableView.registerCell(forClass: G14Cell.self)

        tableView.buildSections()
    }

    private func row(viewItem: CoinMarketsViewModel.ViewItem, index: Int, isLast: Bool) -> RowProtocol {
        Row<G14Cell>(
                id: "item-\(index)",
                height: .heightDoubleLineCell,
                bind: { cell, _ in
                    cell.set(backgroundStyle: .transparent, isLast: isLast)
                    cell.setTitleImage(urlString: viewItem.marketImageUrl)
                    cell.titleImageCornerRadius = .cornerRadius4
                    cell.titleImageBackgroundColor = .themeSteel10
                    cell.topText = viewItem.market
                    cell.bottomText = viewItem.pair
                    cell.primaryValueText = viewItem.rate
                    cell.secondaryTitleText = "market.market_field.vol".localized
                    cell.secondaryValueText = viewItem.volume
                }
        )
    }

}

extension CoinMarketsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let viewItems = viewModel.viewItems

        return [
            Section(
                    id: "main",
                    headerState: .margin(height: .margin12),
                    footerState: .margin(height: .margin32),
                    rows: viewItems.enumerated().map { index, viewItem in
                        row(viewItem: viewItem, index: index, isLast: index == viewItems.count - 1)
                    }
            )
        ]
    }

}
