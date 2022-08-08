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

    let tableView = SectionsTableView(style: .grouped)
    private weak var scanQrViewController: WalletConnectScanQrViewController?

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

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect_list.title".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "qr_scan_24"), style: .plain, target: self, action: #selector(startNewConnection))

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

        view.addSubview(bottomButtonHolder)
        bottomButtonHolder.snp.makeConstraints { maker in
            maker.top.equalTo(tableView.snp.bottom).offset(-CGFloat.margin16)
            maker.leading.trailing.bottom.equalToSuperview()
        }

        bottomButtonHolder.addSubview(bottomButton)
        bottomButton.snp.makeConstraints { maker in
            maker.edges.equalToSuperview().inset(CGFloat.margin24)
        }

        bottomButton.set(style: .yellow)
        bottomButton.setTitle("wallet_connect_list.new_connection".localized, for: .normal)
        bottomButton.addTarget(self, action: #selector(startNewConnection), for: .touchUpInside)

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
        let scanQrViewController = WalletConnectScanQrViewController()
        self.scanQrViewController = scanQrViewController
        scanQrViewController.delegate = self

        present(scanQrViewController, animated: true)
    }

    private func show(walletConnectMainModule: IWalletConnectMainService) {
        guard let viewController = WalletConnectMainModule.viewController(service: walletConnectMainModule, sourceViewController: self) else {
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

extension WalletConnectListViewController: SectionsDataSource {

    func buildSections() -> [SectionProtocol] {
        (listViewV2.sections(tableView: tableView) + listViewV1.sections(tableView: tableView)).compactMap { $0 }
    }

}

extension WalletConnectListViewController: IScanQrViewControllerDelegate {

    func didScan(viewController: UIViewController, string: String) {
        viewModel.didScan(string: string)
    }

}
