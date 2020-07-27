import UIKit
import SectionsTableView
import SnapKit
import ThemeKit

class SwapTokenSelectViewController: ThemeViewController {
    private let delegate: ISwapTokenSelectViewDelegate

    private var viewItems = [CoinBalanceViewItem]()

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: ISwapTokenSelectViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "choose_coin.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.close".localized, style: .plain, target: self, action: #selector(onClose))

        tableView.registerCell(forClass: SwapTokenSelectCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.onLoad()

        tableView.buildSections()
    }

    @objc func onClose() {
        delegate.onTapClose()
    }

    private func rows(viewItems: [CoinBalanceViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { (index, viewItem) in
            Row<SwapTokenSelectCell>(
                id: "coin_\(viewItem.coin.id)",
                height: .heightDoubleLineCell,
                autoDeselect: true,
                bind: { cell, _ in
                    cell.bind(coin: viewItem.coin, balance: viewItem.balance, last: index == viewItems.count - 1)
                },
                action: { [weak self] _ in
                    self?.onSelect(coin: viewItem.coin)
                }
            )
        }
    }

    private func onSelect(coin: Coin) {
        delegate.onSelect(coin: coin)
    }

}

extension SwapTokenSelectViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "coins",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin8x),
                    rows: rows(viewItems: viewItems)
            )
        ]
    }

}

extension SwapTokenSelectViewController: ISwapTokenSelectView {

    func set(viewItems: [CoinBalanceViewItem]) {
        self.viewItems = viewItems

        tableView.reload()
    }

}
