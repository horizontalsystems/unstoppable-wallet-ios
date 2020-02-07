import UIKit
import SectionsTableView
import ThemeKit

class CreateWalletViewController: ThemeViewController {
    private let delegate: ICreateWalletViewDelegate

    private var featuredViewItems = [CoinToggleViewItem]()
    private var viewItems = [CoinToggleViewItem]()

    private let tableView = SectionsTableView(style: .grouped)

    init(delegate: ICreateWalletViewDelegate) {
        self.delegate = delegate

        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "select_coins.choose_crypto".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "create_wallet.create_button".localized, style: .done, target: self, action: #selector(onTapCreateButton))

        tableView.registerCell(forClass: CoinToggleCell.self)
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

    @objc func onTapCreateButton() {
        delegate.onTapCreateButton()
    }

    @objc func onTapCancelButton() {
        delegate.onTapCancelButton()
    }

    private func rows(viewItems: [CoinToggleViewItem]) -> [RowProtocol] {
        viewItems.enumerated().map { (index, viewItem) in
            var action: ((CoinToggleCell) -> ())?

            if case .toggleHidden = viewItem.state {
                action = { [weak self] _ in
                    self?.delegate.onSelect(viewItem: viewItem)
                }
            }

            return Row<CoinToggleCell>(
                    id: "coin_\(viewItem.coin.id)",
                    hash: "coin_\(viewItem.state)",
                    height: .heightDoubleLineCell,
                    autoDeselect: true,
                    bind: { [weak self] cell, _ in
                        cell.bind(
                                coin: viewItem.coin,
                                state: viewItem.state,
                                last: index == viewItems.count - 1
                        ) { [weak self] enabled in
                            self?.onToggle(viewItem: viewItem, enabled: enabled)
                        }
                    },
                    action: action
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

extension CreateWalletViewController: SectionsDataSource {

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

extension CreateWalletViewController: ICreateWalletView {

    func setCancelButton(visible: Bool) {
        if visible {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    func set(featuredViewItems: [CoinToggleViewItem], viewItems: [CoinToggleViewItem]) {
        self.featuredViewItems = featuredViewItems
        self.viewItems = viewItems

        tableView.reload()
    }

    func setCreateButton(enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }

    func showNotSupported(coin: Coin, predefinedAccountType: PredefinedAccountType) {
        let controller = CreateWalletNotSupportedViewController(coin: coin, predefinedAccountType: predefinedAccountType)
        present(controller, animated: true)
    }

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
