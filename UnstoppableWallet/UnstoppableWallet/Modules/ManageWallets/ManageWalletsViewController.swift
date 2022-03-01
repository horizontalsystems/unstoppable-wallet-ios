import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class ManageWalletsViewController: CoinToggleViewController {
    private let viewModel: ManageWalletsViewModel
    private let enableCoinView: EnableCoinView

    private let notFoundLabel = UILabel()

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
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(onTapAddTokenButton))

        view.addSubview(notFoundLabel)
        notFoundLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.top.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin48)
        }

        notFoundLabel.numberOfLines = 0
        notFoundLabel.textAlignment = .center
        notFoundLabel.text = "manage_wallets.not_found".localized
        notFoundLabel.font = .subhead2
        notFoundLabel.textColor = .themeGray

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
        notFoundLabel.isHidden = !visible
    }

}
