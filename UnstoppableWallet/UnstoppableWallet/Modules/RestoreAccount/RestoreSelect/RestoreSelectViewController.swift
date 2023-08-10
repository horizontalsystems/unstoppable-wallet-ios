import Foundation
import UIKit
import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class RestoreSelectViewController: CoinToggleViewController {
    private let viewModel: RestoreSelectViewModel
    private let blockchainTokensView: BlockchainTokensView
    private let restoreSettingsView: RestoreSettingsView

    private weak var returnViewController: UIViewController?

    init(viewModel: RestoreSelectViewModel, blockchainTokensView: BlockchainTokensView, restoreSettingsView: RestoreSettingsView, returnViewController: UIViewController?) {
        self.viewModel = viewModel
        self.blockchainTokensView = blockchainTokensView
        self.restoreSettingsView = restoreSettingsView
        self.returnViewController = returnViewController

        super.init(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.searchController = nil

        title = "restore_select.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.import".localized, style: .done, target: self, action: #selector(onTapRightBarButton))

        blockchainTokensView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }
        restoreSettingsView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }

        subscribe(disposeBag, viewModel.restoreEnabledDriver) { [weak self] in self?.navigationItem.rightBarButtonItem?.isEnabled = $0 }
        subscribe(disposeBag, viewModel.disableBlockchainSignal) { [weak self] in self?.setToggle(on: false, uid: $0) }
        subscribe(disposeBag, viewModel.successSignal) { [weak self] in
            HudHelper.instance.show(banner: .imported)
            (self?.returnViewController ?? self)?.dismiss(animated: true)
        }
    }

    private func open(controller: UIViewController) {
        navigationItem.searchController?.dismiss(animated: true)
        present(controller, animated: true)
    }

    @objc private func onTapRightBarButton() {
        viewModel.onRestore()
    }

}
