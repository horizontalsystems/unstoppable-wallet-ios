import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import UIExtensions

class CoinSelectViewController: ThemeViewController {
    private let disposeBag = DisposeBag()
    private let delegate: ICoinSelectDelegate

    private let viewModel: CoinSelectViewModel
    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems = [CoinBalanceViewItem]()

    init(viewModel: CoinSelectViewModel, delegate: ICoinSelectDelegate) {
        self.viewModel = viewModel
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

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.registerCell(forClass: SwapTokenSelectCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        subscribe(disposeBag, viewModel.coinViewItems) { [weak self] in self?.handle(viewItems: $0) }
    }

    @objc func onClose() {
        dismiss(animated: true)
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
                    self?.onSelectCoin(at: index)
                }
            )
        }
    }

    private func onSelectCoin(at index: Int) {
        if let coin = viewModel.coin(at: index) {
            delegate.didSelect(coin: coin)
        }

        onClose()
    }

    private func handle(viewItems: [CoinBalanceViewItem]) {
        self.viewItems = viewItems

        tableView.reload()
    }

}

extension CoinSelectViewController: SectionsDataSource {

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
