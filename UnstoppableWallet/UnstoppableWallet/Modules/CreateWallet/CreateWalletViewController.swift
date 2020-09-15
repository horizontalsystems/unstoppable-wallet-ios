import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class CreateWalletViewController: CoinToggleViewController {
    private let viewModel: CreateWalletViewModel
    private let presentationMode: CreateWalletModule.PresentationMode

    init(viewModel: CreateWalletViewModel, presentationMode: CreateWalletModule.PresentationMode) {
        self.viewModel = viewModel
        self.presentationMode = presentationMode

        super.init(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "select_coins.choose_crypto".localized
        searchController.searchBar.placeholder = "placeholder.search".localized

        if presentationMode == .inApp {
            navigationItem.leftBarButtonItem = UIBarButtonItem(title: "button.cancel".localized, style: .plain, target: self, action: #selector(onTapCancelButton))
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "create_wallet.create_button".localized, style: .done, target: self, action: #selector(onTapCreateButton))

        viewModel.createEnabledDriver
                .drive(onNext: { [weak self] enabled in
                    self?.navigationItem.rightBarButtonItem?.isEnabled = enabled
                })
                .disposed(by: disposeBag)

        viewModel.errorSignal
                .emit(onNext: { error in
                    HudHelper.instance.showError(title: error.smartDescription)
                })
                .disposed(by: disposeBag)

        viewModel.enableFailedSignal
                .emit(onNext: { [weak self] coin in
                    self?.revert(coin: coin)
                })
                .disposed(by: disposeBag)

        viewModel.finishSignal
                .emit(onNext: { [weak self] in
                    self?.finish()
                })
                .disposed(by: disposeBag)
    }

    @objc private func onTapCancelButton() {
        dismiss(animated: true)
    }

    @objc private func onTapCreateButton() {
        viewModel.onCreate()
    }

    private func finish() {
        switch presentationMode {
        case .initial:
            UIApplication.shared.keyWindow?.set(newRootController: MainModule.instance(selectedTab: .balance))
        case .inApp:
            dismiss(animated: true)
        }
    }

}
