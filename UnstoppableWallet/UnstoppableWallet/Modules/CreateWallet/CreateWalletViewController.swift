import UIKit
import SectionsTableView
import SnapKit
import ThemeKit
import RxSwift
import RxCocoa

class CreateWalletViewController: CoinToggleViewController {
    private let viewModel: CreateWalletViewModel
    private var onComplete: (() -> ())?

    init(viewModel: CreateWalletViewModel, onComplete: (() -> ())? = nil) {
        self.viewModel = viewModel
        self.onComplete = onComplete

        super.init(viewModel: viewModel)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "select_coins.choose_crypto".localized
        navigationItem.searchController?.searchBar.placeholder = "placeholder.search".localized

        if navigationController?.viewControllers.first == self {
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
                    self?.setToggle(on: false, coin: coin)
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
        if let onComplete = onComplete {
            onComplete()
        } else {
            dismiss(animated: true)
        }
    }

}
