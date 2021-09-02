import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa

class RestoreSelectViewController: CoinToggleViewController {
    private let viewModel: RestoreSelectViewModel
    private let enableCoinView: EnableCoinView
    private let enableCoinsView: EnableCoinsView

    init(viewModel: RestoreSelectViewModel, enableCoinView: EnableCoinView, enableCoinsView: EnableCoinsView) {
        self.viewModel = viewModel
        self.enableCoinView = enableCoinView
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

        enableCoinView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }
        enableCoinsView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
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

    private func open(controller: UIViewController) {
        navigationItem.searchController?.dismiss(animated: true)
        present(controller, animated: true)
    }

    @objc func onTapRightBarButton() {
        viewModel.onRestore()
    }

}
