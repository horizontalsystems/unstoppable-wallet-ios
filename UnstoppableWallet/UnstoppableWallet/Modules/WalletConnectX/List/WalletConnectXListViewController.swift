import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class WalletConnectXListViewController: ThemeViewController {
    private let disposeBag = DisposeBag()

    private let viewModel: WalletConnectXListViewModel
    private let listViewV1: WalletConnectV1XListView
    private let listViewV2: WalletConnectV2XListView

    private let emptyView = ErrorMessageView()

    let tableView = SectionsTableView(style: .grouped)
    private weak var scanQrViewController: WalletConnectXScanQrViewController?

    init(listViewV1: WalletConnectV1XListView, listViewV2: WalletConnectV2XListView, viewModel: WalletConnectXListViewModel) {
        self.listViewV1 = listViewV1
        self.listViewV2 = listViewV2
        self.viewModel = viewModel

        super.init()

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect_list.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "qr_scan_24"), style: .plain, target: self, action: #selector(startNewConnection))

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.registerCell(forClass: A1Cell.self)
        tableView.registerCell(forClass: G1Cell.self)
        tableView.registerHeaderFooter(forClass: SubtitleHeaderFooterView.self)
        tableView.registerHeaderFooter(forClass: BottomDescriptionHeaderFooterView.self)
        tableView.sectionDataSource = self

        view.addSubview(emptyView)
        emptyView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }

        emptyView.text = "wallet_connect.list.empty_view_text".localized
        emptyView.setButton(title: "wallet_connect.list.empty_view_button_text".localized)
        emptyView.image = UIImage(named: "wallet_connect_48")
        emptyView.onTapButton = { [weak self] in self?.startNewConnection() }

        subscribe(disposeBag, viewModel.showWalletConnectMainModuleSignal) { [weak self] in self?.show(walletConnectMainModule: $0) }
        subscribe(disposeBag, viewModel.newConnectionErrorSignal) { [weak self] in self?.show(newConnectionError: $0) }
        subscribe(disposeBag, listViewV1.reloadTableSignal) { [weak self] in self?.syncItems() }
        subscribe(disposeBag, listViewV2.reloadTableSignal) { [weak self] in self?.syncItems() }

        listViewV1.viewDidLoad()
        listViewV2.viewDidLoad()

        if viewModel.emptySessionList {
            startNewConnection()
        }
    }

    private func syncItems() {
        emptyView.isHidden = !viewModel.emptySessionList

        tableView.reload()
    }

    @objc private func startNewConnection() {
        let scanQrViewController = WalletConnectXScanQrViewController()
        self.scanQrViewController = scanQrViewController
        scanQrViewController.delegate = self

        present(scanQrViewController, animated: true)
    }

    private func show(walletConnectMainModule: IWalletConnectXMainService) {
        guard let viewController = WalletConnectXMainModule.viewController(service: walletConnectMainModule, sourceViewController: self) else {
            return
        }

        guard let scanQrViewController = scanQrViewController else {
            present(viewController, animated: true)
            return
        }

        scanQrViewController.dismiss(animated: true) { [weak self] in
            self?.present(viewController, animated: true)
        }
    }

    private func show(newConnectionError: String) {
        let viewController = WalletConnectErrorViewController(error: newConnectionError)
        viewController.delegate = scanQrViewController

        scanQrViewController?.present(ThemeNavigationController(rootViewController: viewController), animated: true)
    }

}

extension WalletConnectXListViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        (listViewV2.sections + listViewV1.sections).compactMap { $0 }
    }

}

extension WalletConnectXListViewController: IScanQrViewControllerDelegate {

    func didScan(viewController: UIViewController, string: String) {
        viewModel.didScan(string: string)
    }

}
