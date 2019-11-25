import UIKit
import SectionsTableView

class CreateWalletViewController: WalletViewController {
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

        title = "create_wallet.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "create_wallet.create_button".localized, style: .done, target: self, action: #selector(onTapCreateButton))

        tableView.registerCell(forClass: CoinToggleCell.self)
        tableView.registerHeaderFooter(forClass: TopDescriptionHeaderFooterView.self)
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

    @objc func onTapCreateButton() {
        delegate.onTapCreateButton()
    }

    @objc func onTapCancelButton() {
        delegate.onTapCancelButton()
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
                        ) { enabled in
                            if enabled {
                                self?.delegate.onEnable(viewItem: viewItem)
                            } else {
                                self?.delegate.onDisable(viewItem: viewItem)
                            }
                        }
                    }
            )
        }
    }

}

extension CreateWalletViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        let descriptionText = "select_coins.description".localized

        let headerState: ViewState<TopDescriptionHeaderFooterView> = .cellType(hash: "top_description", binder: { view in
            view.bind(text: descriptionText)
        }, dynamicHeight: { [unowned self] _ in
            TopDescriptionHeaderFooterView.height(containerWidth: self.tableView.bounds.width, text: descriptionText)
        })

        return [
            Section(
                    id: "featured_coins",
                    headerState: headerState,
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

    func show(error: Error) {
        HudHelper.instance.showError(title: error.localizedDescription)
    }

}
