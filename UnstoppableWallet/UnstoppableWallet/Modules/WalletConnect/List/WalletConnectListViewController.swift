import ComponentKit
import RxCocoa
import RxSwift
import SectionsTableView
import ThemeKit
import UIKit
import WalletConnectSign

class WalletConnectListViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: WalletConnectListViewModel

    private let emptyView = PlaceholderView()
    private let bottomButtonHolder = BottomGradientHolder()
    private let bottomButton = PrimaryButton()

    private let tableView = SectionsTableView(style: .grouped)

    private var viewItems = [WalletConnectListViewModel.ViewItem]()
    private var pairingCount: Int = 0

    init(viewModel: WalletConnectListViewModel) {
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect_list.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "circle_information_24"), style: .plain, target: self, action: #selector(onTapInfo))
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.leading.top.trailing.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.sectionDataSource = self

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        emptyView.image = UIImage(named: "wallet_connect_48")
        emptyView.text = "wallet_connect.list.empty_view_text".localized

        bottomButtonHolder.add(to: self, under: tableView)
        bottomButtonHolder.addSubview(bottomButton)

        bottomButton.set(style: .yellow)
        bottomButton.setTitle("wallet_connect_list.new_connection".localized, for: .normal)
        bottomButton.addTarget(self, action: #selector(startNewConnection), for: .touchUpInside)

        subscribe(disposeBag, viewModel.disableNewConnectionSignal) { [weak self] in self?.disableNewConnection($0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.showError(text: $0) }
        subscribe(disposeBag, viewModel.viewItemsDriver) { [weak self] in self?.sync(viewItems: $0) }
        subscribe(disposeBag, viewModel.pairingCountDriver) { [weak self] in self?.sync(pairingCount: $0) }
        subscribe(disposeBag, viewModel.showDisconnectingSignal) { HudHelper.instance.show(banner: .disconnectingWalletConnect) }
        subscribe(disposeBag, viewModel.showSuccessSignal) { HudHelper.instance.show(banner: .disconnectedWalletConnect) }
        subscribe(disposeBag, viewModel.showWalletConnectSessionSignal) { [weak self] in self?.show(session: $0) }

        if viewModel.emptyList {
            startNewConnection()
        }
    }

    private func sync(viewItems: [WalletConnectListViewModel.ViewItem]? = nil, pairingCount: Int? = nil) {
        if let viewItems { self.viewItems = viewItems }
        if let pairingCount { self.pairingCount = pairingCount }

        emptyView.isHidden = !viewModel.emptyList

        tableView.reload()
    }

    @objc private func onTapInfo() {
        guard let url = FaqUrlHelper.walletConnectUrl else {
            return
        }

        let module = MarkdownModule.viewController(url: url, handleRelativeUrl: false)
        present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    @objc private func startNewConnection() {
        let scanQrViewController = ScanQrViewController(reportAfterDismiss: true, pasteEnabled: true)
        scanQrViewController.didFetch = { [weak self] in self?.viewModel.didScan(string: $0) }

        present(scanQrViewController, animated: true)
    }

    private func show(session: WalletConnectSign.Session) {
        guard let viewController = WalletConnectMainModule.viewController(session: session, sourceViewController: self) else {
            return
        }

        navigationController?.present(viewController, animated: true)
    }

    private func showPairings() {
        let viewController = WalletConnectPairingModule.viewController()

        navigationController?.pushViewController(viewController, animated: true)
    }

    private func disableNewConnection(_ isDisabled: Bool) {
        bottomButton.isEnabled = !isDisabled
        navigationItem.rightBarButtonItem?.isEnabled = !isDisabled
    }

    private func showError(text: String) {
        HudHelper.instance.show(banner: .error(string: text))
    }

    private func show(newConnectionError: String) {
        let viewController = BottomSheetModule.viewController(
            image: .local(image: UIImage(named: "wallet_connect_24")?.withTintColor(.themeJacob)),
            title: "WalletConnect",
            items: [
                .highlightedDescription(text: newConnectionError),
            ],
            buttons: [
                .init(style: .yellow, title: "alert.try_again".localized, actionType: .afterClose) { [weak self] in self?.startNewConnection() },
                .init(style: .transparent, title: "button.cancel".localized),
            ]
        )

        present(viewController, animated: true)
    }

    private func deleteRowAction(id: Int) -> RowAction {
        RowAction(pattern: .icon(
            image: UIImage(named: "circle_minus_shifted_24"),
            background: UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        ), action: { [weak self] _ in
            self?.viewModel.kill(id: id)
        })
    }

    private func cell(tableView: UITableView, viewItem: WalletConnectListViewModel.ViewItem, isFirst: Bool, isLast: Bool, action: @escaping () -> Void) -> RowProtocol? {
        let rowAction = deleteRowAction(id: viewItem.id)

        let elements: [CellBuilderNew.CellElement] = [
            .image32 { component in
                component.imageView.cornerRadius = .cornerRadius8
                component.imageView.layer.cornerCurve = .continuous
                component.imageView.contentMode = .scaleAspectFit
                component.setImage(urlString: viewItem.imageUrl, placeholder: UIImage(named: "placeholder_rectangle_32"))
            },
            .vStackCentered([
                .text { component in
                    component.font = .body
                    component.textColor = .themeLeah
                    component.text = viewItem.title
                },
                .margin(1),
                .text { component in
                    component.font = .subhead2
                    component.textColor = .themeGray
                    component.text = viewItem.description
                },
            ]),
            .badge { component in
                if let badge = viewItem.badge {
                    component.isHidden = false
                    component.badgeView.set(style: .medium)
                    component.badgeView.text = badge
                } else {
                    component.isHidden = true
                }
            },
            .image20 { component in
                component.imageView.image = UIImage(named: "arrow_big_forward_20")
            },
        ]

        return CellBuilderNew.row(
            rootElement: .hStack(elements),
            tableView: tableView,
            id: viewItem.title,
            height: .heightDoubleLineCell,
            autoDeselect: true,
            rowActionProvider: { [rowAction] },
            bind: { cell in cell.set(backgroundStyle: .lawrence, isFirst: isFirst, isLast: isLast) },
            action: action
        )
    }

    private func pairingCountCell(tableView: SectionsTableView, pairingCount: Int) -> RowProtocol {
        tableView.universalRow48(id: "session-pairing",
                                 title: .body("wallet_connect.list.pairings".localized),
                                 value: .subhead1("\(pairingCount)", color: .themeGray),
                                 accessoryType: .disclosure,
                                 autoDeselect: true,
                                 isFirst: true,
                                 isLast: true,
                                 action: { [weak self] in self?.showPairings() })
    }

    private func pairingSection(tableView: SectionsTableView, showHeader: Bool) -> SectionProtocol? {
        guard pairingCount != 0 else {
            return nil
        }

        let cell = pairingCountCell(tableView: tableView, pairingCount: pairingCount)
        return Section(
            id: "section_pairing",
            headerState: showHeader ? tableView.sectionHeader(text: "wallet_connect.list.version_text".localized("2.0")) : .margin(height: 0),
            footerState: .margin(height: .margin24),
            rows: [cell]
        )
    }

    private func section(tableView: SectionsTableView, viewItems: [WalletConnectListViewModel.ViewItem]) -> SectionProtocol? {
        guard !viewItems.isEmpty else {
            return nil
        }

        return Section(
            id: "section_2",
            headerState: tableView.sectionHeader(text: "wallet_connect.list.version_text".localized("2.0")),
            footerState: .margin(height: .margin24),
            rows: viewItems.enumerated().compactMap { index, viewItem in
                let isFirst = index == 0
                let isLast = index == viewItems.count - 1

                return cell(tableView: tableView, viewItem: viewItem, isFirst: isFirst, isLast: isLast) { [weak self] in
                    self?.viewModel.showSession(id: viewItem.id)
                }
            }
        )
    }
}

extension WalletConnectListViewController: SectionsDataSource {
    func buildSections() -> [SectionProtocol] {
        var sections: [SectionProtocol] = [Section(id: "top-margin", headerState: .margin(height: .margin12))]

        sections.append(contentsOf: [
            section(tableView: tableView, viewItems: viewItems),
            pairingSection(tableView: tableView, showHeader: viewItems.isEmpty),
        ].compactMap { $0 })

        return sections
    }
}
