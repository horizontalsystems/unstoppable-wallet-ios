import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa

class RestoreSelectCoinsViewController: CoinToggleViewController {
    private let restoreView: RestoreView
    private let viewModel: RestoreSelectCoinsViewModel

    init(restoreView: RestoreView, viewModel: RestoreSelectCoinsViewModel) {
        self.restoreView = restoreView
        self.viewModel = viewModel

        super.init(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "select_coins.choose_crypto".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(onTapRightBarButton))

        viewModel.restoreEnabledDriver
                .drive(onNext: { [weak self] enabled in
                    self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
                })
                .disposed(by: disposeBag)

        viewModel.openDerivationSettingsSignal
                .emit(onNext: { [weak self] coin, currentDerivation in
                    self?.showDerivationSettings(coin: coin, currentDerivation: currentDerivation)
                })
                .disposed(by: disposeBag)

        viewModel.enabledCoinsSignal
                .emit(onNext: { [weak self] coins in
                    self?.restoreView.viewModel.onSelect(coins: coins)
                })
                .disposed(by: disposeBag)
    }

    @objc func onTapRightBarButton() {
        viewModel.onRestore()
    }

    private func showDerivationSettings(coin: Coin, currentDerivation: MnemonicDerivation) {
        let module = DerivationSettingRouter.module(coin: coin, currentDerivation: currentDerivation, delegate: self)
        present(module, animated: true)
    }

}

extension RestoreSelectCoinsViewController: IDerivationSettingDelegate {

    func onSelect(derivationSetting: DerivationSetting, coin: Coin) {
        viewModel.onSelect(derivationSetting: derivationSetting, coin: coin)
    }

    func onCancelSelectDerivation(coin: Coin) {
        revert(coin: coin)
    }

}
