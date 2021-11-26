import ThemeKit
import SectionsTableView
import RxSwift
import RxCocoa
import ComponentKit

class RestoreSelectViewController: CoinToggleViewController {
    private let viewModel: RestoreSelectViewModel
    private let enableCoinView: EnableCoinView
    private let enableCoinsView: EnableCoinsView

    private let notFoundLabel = UILabel()

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

        title = "restore_select.title".localized
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "button.restore".localized, style: .done, target: self, action: #selector(onTapRightBarButton))

        view.addSubview(notFoundLabel)
        notFoundLabel.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin48)
            maker.top.equalTo(view.safeAreaLayoutGuide).inset(CGFloat.margin48)
        }

        notFoundLabel.numberOfLines = 0
        notFoundLabel.textAlignment = .center
        notFoundLabel.text = "restore_select.not_found".localized
        notFoundLabel.font = .subhead2
        notFoundLabel.textColor = .themeGray

        enableCoinView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }
        enableCoinsView.onOpenController = { [weak self] controller in
            self?.open(controller: controller)
        }

        subscribe(disposeBag, viewModel.notFoundVisibleDriver) { [weak self] in self?.setNotFound(visible: $0) }
        subscribe(disposeBag, viewModel.restoreEnabledDriver) { [weak self] in self?.navigationItem.rightBarButtonItem?.isEnabled = $0 }
        subscribe(disposeBag, viewModel.successSignal) { [weak self] in self?.dismiss(animated: true) }
        subscribe(disposeBag, viewModel.disableCoinSignal) { [weak self] in self?.setToggle(on: false, coin: $0) }
        subscribe(disposeBag, viewModel.autoEnabledItemsSignal) { [weak self] in self?.showEnabledMessage(count: $0) }
    }

    private func showEnabledMessage(count: Int) {
        if count == 0 {
            HudHelper.instance.showAttention(title: "enable_coins.enabled_no_coins".localized)
        } else {
            HudHelper.instance.showSuccess(title: "enable_coins.enabled_coins".localized(String(count)))
        }
    }

    private func open(controller: UIViewController) {
        navigationItem.searchController?.dismiss(animated: true)
        present(controller, animated: true)
    }

    @objc private func onTapRightBarButton() {
        viewModel.onRestore()
    }

    private func setNotFound(visible: Bool) {
        notFoundLabel.isHidden = !visible
    }

}
