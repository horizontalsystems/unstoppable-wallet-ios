import UIKit
import SectionsTableView
import ThemeKit

class RestoreCoinsViewController: ThemeViewController {
    private let delegate: IRestoreCoinsViewDelegate

    private var featuredViewItems = [CoinToggleViewItem]()
    private var viewItems = [CoinToggleViewItem]()

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: IRestoreCoinsViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "select_coins.choose_crypto".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(onTapRestore))

        tableView.registerCell(forClass: CoinToggleCell.self)
        tableView.sectionDataSource = self

        tableView.backgroundColor = .clear
        tableView.allowsSelection = false
        tableView.separatorStyle = .none

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        delegate.onLoad()

        tableView.buildSections()
    }

    @objc func onTapRestore() {
        delegate.onTapRestore()
    }

    private func rows(viewItems: [CoinToggleViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { (index, viewItem) in
            Row<CoinToggleCell>(
                    id: "coin_\(viewItem.coin.id)",
                    hash: "coin_\(viewItem.state)",
                    height: .heightDoubleLineCell,
                    bind: { [weak self] cell, _ in
                        cell.bind(
                                coin: viewItem.coin,
                                state: viewItem.state,
                                last: index == viewItems.count - 1
                        ) { [weak self] enabled in
                            self?.onToggle(viewItem: viewItem, enabled: enabled)
                        }
                    }
            )
        }
    }

    private func onToggle(viewItem: CoinToggleViewItem, enabled: Bool) {
        viewItem.state = .toggleVisible(enabled: enabled)

        if enabled {
            delegate.onEnable(viewItem: viewItem)
        } else {
            delegate.onDisable(viewItem: viewItem)
        }
    }

}

extension RestoreCoinsViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [
            Section(
                    id: "featured_coins",
                    headerState: .margin(height: .margin3x),
                    footerState: .margin(height: .margin8x),
                    rows: rows(viewItems: featuredViewItems)
            ),
            Section(
                    id: "coins",
                    footerState: .margin(height: .margin8x),
                    rows: rows(viewItems: viewItems)
            )
        ]
    }

}

extension RestoreCoinsViewController: IRestoreCoinsView {

    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem]) {
        self.featuredViewItems = featuredViewItems
        self.viewItems = viewItems

        tableView.reload()
    }

    func setProceedButton(enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }

}
