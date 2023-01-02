import UIKit
import RxSwift
import RxCocoa

class CoinSettingsView {
    private let viewModel: CoinSettingsViewModel
    private let disposeBag = DisposeBag()

    var onOpenController: ((UIViewController) -> ())?

    init(viewModel: CoinSettingsViewModel) {
        self.viewModel = viewModel

        subscribe(disposeBag, viewModel.openRequestSignal) { [weak self] in self?.open(request: $0) }
    }

    private func open(request: CoinSettingsService.Request) {
        let controller: UIViewController

        switch request.type {
        case .btc:
            let config = BtcBlockchainSettingsModule.Config(
                    blockchain: request.blockchain,
                    accountType: request.accountType,
                    accountOrigin: request.accountOrigin,
                    coinSettingsArray: request.coinSettingsArray,
                    mode: request.isRestore ? .restore(initial: request.initial) : .manage(initial: request.initial)
            )

            controller = BtcBlockchainSettingsModule.viewController(config: config, delegate: self)
        case .zcash:
            fatalError() // todo
        }

        onOpenController?(controller)
    }

}

extension CoinSettingsView: IBtcBlockchainSettingsDelegate {

    func didApprove(coinSettingsArray: [CoinSettings]) {
        viewModel.onApprove(coinSettingsArray: coinSettingsArray)
    }

    func didCancel() {
        viewModel.onCancelApprove()
    }

}
