import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class ManageWalletsViewController: CoinToggleViewController {
    private let viewModel: ManageWalletsViewModel
    private let enableCoinView: EnableCoinView

    private let notFoundPlaceholder = PlaceholderView(layoutType: .keyboard)

    init(viewModel: ManageWalletsViewModel, enableCoinView: EnableCoinView) {
        self.viewModel = viewModel
        self.enableCoinView = enableCoinView

        super.init(viewModel: viewModel)

        hidesBottomBarWhenPushed = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "manage_wallets.title".localized
        navigationItem.searchController?.searchBar.placeholder = "manage_wallets.search_placeholder".localized

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.done".localized, style: .done, target: self, action: #selector(onTapDoneButton))

        if viewModel.addTokenEnabled {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onTapAddTokenButton))
        }

        view.addSubview(notFoundPlaceholder)
        notFoundPlaceholder.snp.makeConstraints { maker in
            maker.edges.equalTo(view.safeAreaLayoutGuide)
        }

        notFoundPlaceholder.image = UIImage(named: "not_found_48")
        notFoundPlaceholder.text = "manage_wallets.not_found".localized

        enableCoinView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }

        subscribe(disposeBag, viewModel.notFoundVisibleDriver) { [weak self] in self?.setNotFound(visible: $0) }
        subscribe(disposeBag, viewModel.disableCoinSignal) { [weak self] in self?.setToggle(on: false, uid: $0.uid) }
    }

    private func open(controller: UIViewController) {
        navigationItem.searchController?.dismiss(animated: true)
        present(controller, animated: true)
    }

    @objc private func onTapDoneButton() {
        dismiss(animated: true)
    }

    @objc private func onTapAddTokenButton() {
        guard let module = AddTokenModule.viewController() else {
            return
        }

        present(module, animated: true)
    }

    private func setNotFound(visible: Bool) {
        notFoundPlaceholder.isHidden = !visible
    }

    override func onTapToggleHidden(viewItem: CoinToggleViewModel.ViewItem) {
        let viewController = InformationModule.simpleInfo(
                title: "manage_wallets.not_supported".localized,
                image: UIImage(named: "warning_2_24")?.withTintColor(.themeJacob),
                description: "manage_wallets.not_supported.description".localized(viewModel.accountTypeDescription, viewItem.subtitle),
                buttonTitle: "button.close".localized,
                onTapButton: InformationModule.afterClose())

        present(viewController, animated: true)
    }

}
