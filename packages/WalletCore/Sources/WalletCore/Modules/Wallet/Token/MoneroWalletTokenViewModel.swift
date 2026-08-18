import Combine
import Foundation
import RxSwift

class MoneroWalletTokenViewModel: ObservableObject {
    private let adapterManager = Core.shared.adapterManager
    private let restoreSettingsService = RestoreSettingsService(manager: Core.shared.restoreSettingsManager)
    private let disposeBag = DisposeBag()

    let wallet: Wallet

    @Published var birthdayHeight: Int?
    @Published var activeAccountTitle: String = ""

    // Cached: adapterManager.adapter(for:) is a cross-queue sync, too expensive to run on
    // every SwiftUI render pass.
    let adapter: MoneroAdapter?

    init(wallet: Wallet) {
        self.wallet = wallet
        adapter = Core.shared.adapterManager.adapter(for: wallet) as? MoneroAdapter

        birthdayHeight = restoreSettingsService.settings(accountId: wallet.account.id, blockchainType: wallet.token.blockchainType).birthdayHeight

        syncActiveAccount()

        if let adapter {
            adapter.accountsObservable
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] _ in
                    self?.syncActiveAccount()
                })
                .disposed(by: disposeBag)
        }
    }

    private func syncActiveAccount() {
        guard let adapter else {
            activeAccountTitle = ""
            return
        }

        let index = adapter.activeAccountIndex
        if let account = adapter.accounts.first(where: { $0.index == index }), let label = account.label, !label.isEmpty {
            activeAccountTitle = "\(index). \(label)"
        } else {
            activeAccountTitle = "\(index). " + "monero.account".localized
        }
    }
}

extension MoneroWalletTokenViewModel {
    func onChange(birthdayHeight: Int) {
        let blockchainType = wallet.token.blockchainType
        restoreSettingsService.set(birthdayHeight: String(birthdayHeight), account: wallet.account, blokcchainType: blockchainType)
        self.birthdayHeight = birthdayHeight

        adapterManager.recreateAdapter(blockchainType: blockchainType)
    }
}
