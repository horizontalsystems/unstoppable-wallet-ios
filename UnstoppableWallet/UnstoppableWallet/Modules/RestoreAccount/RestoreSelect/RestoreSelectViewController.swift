import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa

class RestoreSelectViewController: CoinToggleViewControllerNew {
    private let viewModel: RestoreSelectViewModel
    private let coinSettingsView: CoinSettingsView
    private let enableCoinsView: EnableCoinsView

    init(viewModel: RestoreSelectViewModel, coinSettingsView: CoinSettingsView, enableCoinsView: EnableCoinsView) {
        self.viewModel = viewModel
        self.coinSettingsView = coinSettingsView
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

        coinSettingsView.onOpenController = { [weak self] controller in
            self?.present(controller, animated: true)
        }
        enableCoinsView.onOpenController = { [weak self] controller in
            self?.present(controller, animated: true)
        }

        subscribe(disposeBag, viewModel.restoreEnabledDriver) { [weak self] enabled in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
        }

        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            self?.dismiss(animated: true)
        }

        subscribe(disposeBag, viewModel.disableCoinSignal) { [weak self] coin in
            self?.setToggle(on: false, coin: coin)
        }
    }

    @objc func onTapRightBarButton() {
        viewModel.onRestore()
    }

}
