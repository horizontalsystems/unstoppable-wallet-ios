import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class ManageWalletsViewController: CoinToggleViewController {
    private let viewModel: ManageWalletsViewModel
    private let blockchainSettingsView: BlockchainSettingsView
    private let enableCoinsView: EnableCoinsView

    init(viewModel: ManageWalletsViewModel, blockchainSettingsView: BlockchainSettingsView, enableCoinsView: EnableCoinsView) {
        self.viewModel = viewModel
        self.blockchainSettingsView = blockchainSettingsView
        self.enableCoinsView = enableCoinsView

        super.init(viewModel: viewModel)

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "manage_coins.title".localized
        navigationItem.searchController?.searchBar.placeholder = "placeholder.search".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "manage_coins.add_token".localized, style: .plain, target: self, action: #selector(onTapAddTokenButton))

        blockchainSettingsView.onOpenController = { [weak self] controller in
            DispatchQueue.main.async {
                self?.present(controller, animated: true)
            }
        }
        enableCoinsView.onOpenController = { [weak self] controller in
            DispatchQueue.main.async {
                self?.present(controller, animated: true)
            }
        }

        subscribe(disposeBag, viewModel.enableCoinSignal) { [weak self] coin in
            self?.setToggle(on: true, coin: coin)
        }
        subscribe(disposeBag, viewModel.disableCoinSignal) { [weak self] coin in
            self?.setToggle(on: false, coin: coin)
        }
    }

    @objc func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc func onTapAddTokenButton() {
        let module = AddTokenSelectorRouter.module(sourceViewController: self)
        present(module, animated: true)
    }

    override func onSelect(viewItem: CoinToggleViewModel.ViewItem) {
        let module = NoAccountRouter.module(coin: viewItem.coin, sourceViewController: self)
        present(module, animated: true)

        viewModel.onAddAccount(coin: viewItem.coin)
    }

}
