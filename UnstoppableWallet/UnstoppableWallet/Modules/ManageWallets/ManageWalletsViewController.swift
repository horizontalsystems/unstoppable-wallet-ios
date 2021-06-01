import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class ManageWalletsViewController: CoinToggleViewController {
    private let viewModel: ManageWalletsViewModel
    private let restoreSettingsView: RestoreSettingsView
    private let coinSettingsView: CoinSettingsView

    init(viewModel: ManageWalletsViewModel, restoreSettingsView: RestoreSettingsView, coinSettingsView: CoinSettingsView) {
        self.viewModel = viewModel
        self.restoreSettingsView = restoreSettingsView
        self.coinSettingsView = coinSettingsView

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

        restoreSettingsView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }
        coinSettingsView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }

        subscribe(disposeBag, viewModel.disableCoinSignal) { [weak self] coin in
            self?.setToggle(on: false, coin: coin)
        }
    }

    private func open(controller: UIViewController) {
        navigationItem.searchController?.dismiss(animated: true)
        present(controller, animated: true)
    }

    @objc func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc func onTapAddTokenButton() {
        let module = AddTokenSelectorRouter.module(sourceViewController: self)
        present(module, animated: true)
    }

}
