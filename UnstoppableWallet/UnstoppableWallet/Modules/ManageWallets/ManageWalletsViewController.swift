import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class ManageWalletsViewController: CoinToggleViewController {
    private let viewModel: ManageWalletsViewModel

    init(viewModel: ManageWalletsViewModel) {
        self.viewModel = viewModel

        super.init(viewModel: viewModel)

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "manage_coins.title".localized
        searchController.searchBar.placeholder = "placeholder.search".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "manage_coins.add_token".localized, style: .plain, target: self, action: #selector(onTapAddTokenButton))

        viewModel.openDerivationSettingsSignal
                .emit(onNext: { [weak self] coin, currentDerivation in
                    self?.showDerivationSettings(coin: coin, currentDerivation: currentDerivation)
                })
                .disposed(by: disposeBag)
    }

    @objc func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc func onTapAddTokenButton() {
        let module = AddTokenRouter.module(sourceViewController: self)
        present(module, animated: true)
    }

    override func onSelect(viewItem: CoinToggleViewModel.ViewItem) {
        let module = NoAccountRouter.module(coin: viewItem.coin, sourceViewController: self)
        present(module, animated: true)
    }

    private func showDerivationSettings(coin: Coin, currentDerivation: MnemonicDerivation) {
        let module = DerivationSettingRouter.module(coin: coin, currentDerivation: currentDerivation, delegate: self)
        present(module, animated: true)
    }

}

extension ManageWalletsViewController: IDerivationSettingDelegate {

    func onSelect(derivationSetting: DerivationSetting, coin: Coin) {
        viewModel.onSelect(derivationSetting: derivationSetting, coin: coin)
    }

    func onCancelSelectDerivation(coin: Coin) {
        revert(coin: coin)
    }

}
