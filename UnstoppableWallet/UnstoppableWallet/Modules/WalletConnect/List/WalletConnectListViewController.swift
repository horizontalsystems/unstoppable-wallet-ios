import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class WalletConnectListViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: WalletConnectListViewModel
    private let listViewV1: WalletConnectV1ListView
    private let listViewV2: WalletConnectV2ListView

    private let emptyView = PlaceholderView()
    private let bottomButtonHolder = BottomGradientHolder()
    private let bottomButton = PrimaryButton()

    private let tableView = SectionsTableView(style: .grouped)

    init(listViewV1: WalletConnectV1ListView, listViewV2: WalletConnectV2ListView, viewModel: WalletConnectListViewModel) {
        self.listViewV1 = listViewV1
        self.listViewV2 = listViewV2
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        if viewModel.isWaitingForSession {
            HudHelper.instance.hide()
        }
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

        subscribe(disposeBag, viewModel.showWalletConnectMainModuleSignal) { [weak self] in self?.show(walletConnectMainModule: $0) }
        subscribe(disposeBag, viewModel.showWalletConnectV2ValidatedSignal) { [weak self] in self?.showV2ValidatedSuccessful(uri: $0) }
        subscribe(disposeBag, viewModel.showWaitingForSessionSignal) { [weak self] in self?.showWaitingForSession(true) }
        subscribe(disposeBag, viewModel.hideWaitingForSessionSignal) { [weak self] in self?.showWaitingForSession(false) }
        subscribe(disposeBag, viewModel.disableNewConnectionSignal) { [weak self] in self?.disableNewConnection($0) }
        subscribe(disposeBag, viewModel.showErrorSignal) { [weak self] in self?.showError(text: $0) }
        subscribe(disposeBag, viewModel.newConnectionErrorSignal) { [weak self] in self?.show(newConnectionError: $0) }
        subscribe(disposeBag, listViewV1.reloadTableSignal) { [weak self] in self?.syncItems() }
        subscribe(disposeBag, listViewV2.reloadTableSignal) { [weak self] in self?.syncItems() }

        listViewV1.viewDidLoad()
        listViewV2.viewDidLoad()

        if viewModel.emptyList {
            startNewConnection()
        }
    }

    @objc private func onTapInfo() {
        guard let url = FaqUrlHelper.walletConnectUrl else {
            return
        }

        let module = MarkdownModule.viewController(url: url, handleRelativeUrl: false)
        present(ThemeNavigationController(rootViewController: module), animated: true)
    }

    private func syncItems() {
        emptyView.isHidden = !viewModel.emptyList

        tableView.reload()
    }

    @objc private func startNewConnection() {
        let scanQrViewController = ScanQrViewController(reportAfterDismiss: true, pasteEnabled: true)
        scanQrViewController.delegate = self
        present(scanQrViewController, animated: true)
    }

    private func show(walletConnectMainModule: WalletConnectV1MainService) {
        guard let viewController = WalletConnectMainModule.viewController(service: walletConnectMainModule, sourceViewController: self) else {
            return
        }

        present(viewController, animated: true)
    }

    private func showV2ValidatedSuccessful(uri: String) {
        viewModel.pairV2(validUri: uri)
    }

    private func showWaitingForSession(_ isShow: Bool) {
        bottomButton.isEnabled = !isShow
        navigationItem.rightBarButtonItem?.isEnabled = !isShow

        if isShow {
            HudHelper.instance.show(banner: .waitingForSession)
        } else {
            HudHelper.instance.hide()
        }
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
                    .highlightedDescription(text: newConnectionError)
                ],
                buttons: [
                    .init(style: .yellow, title: "alert.try_again".localized, actionType: .afterClose) { [ weak self] in self?.startNewConnection() },
                    .init(style: .transparent, title: "button.cancel".localized)
                ]
        )

        present(viewController, animated: true)
    }

}

extension WalletConnectListViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        [Section(id: "top-margin", headerState: .margin(height: .margin12))] +
        (listViewV2.sections(tableView: tableView) + listViewV1.sections(tableView: tableView)).compactMap { $0 }
    }

}

extension WalletConnectListViewController: IScanQrViewControllerDelegate {

    func didFetch(string: String) {
        viewModel.didScan(string: string)
    }

}
