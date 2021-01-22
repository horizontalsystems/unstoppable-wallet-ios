import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa

class RestoreSelectCoinsViewController: CoinToggleViewController {
    private let restoreView: RestoreView
    private let viewModel: RestoreSelectCoinsViewModel
    private let blockchainSettingsView: BlockchainSettingsView
    private let enableCoinsView: EnableCoinsView

    init(restoreView: RestoreView, viewModel: RestoreSelectCoinsViewModel, blockchainSettingsView: BlockchainSettingsView, enableCoinsView: EnableCoinsView) {
        self.restoreView = restoreView
        self.viewModel = viewModel
        self.blockchainSettingsView = blockchainSettingsView
        self.enableCoinsView = enableCoinsView

        super.init(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "select_coins.choose_crypto".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(onTapRightBarButton))

        blockchainSettingsView.onOpenController = { [weak self] controller in
            self?.present(controller, animated: true)
        }
        enableCoinsView.onOpenController = { [weak self] controller in
            self?.present(controller, animated: true)
        }

        subscribe(disposeBag, viewModel.restoreEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
        }

        subscribe(disposeBag, viewModel.enabledCoinsSignal) { [weak self] coins in
            self?.restoreView.viewModel.onSelect(coins: coins)
        }

        subscribe(disposeBag, viewModel.disableCoinSignal) { [weak self] coin in
            self?.setToggle(on: false, coin: coin)
        }
    }

    @objc func onTapRightBarButton() {
        viewModel.onRestore()
    }

}
