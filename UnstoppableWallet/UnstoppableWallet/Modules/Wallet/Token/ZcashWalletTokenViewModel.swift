import Combine
import Foundation
import RxSwift

class ZcashWalletTokenViewModel: ObservableObject {
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let adapterManager = Core.shared.adapterManager
    private let restoreSettingsService = RestoreSettingsService(manager: Core.shared.restoreSettingsManager)
    private let adapter: ZcashAdapter

    private var cancellables = Set<AnyCancellable>()
    private let disposeBag = DisposeBag()

    let wallet: Wallet

    @Published var zCashBalanceData: ZcashBalanceData
    @Published var balanceHidden: Bool
    @Published var birthdayHeight: Int?

    init(adapter: ZcashAdapter, wallet: Wallet) {
        self.adapter = adapter
        self.wallet = wallet
        zCashBalanceData = adapter.zCashBalanceData
        balanceHidden = balanceHiddenManager.balanceHidden

        birthdayHeight = restoreSettingsService.settings(accountId: wallet.account.id, blockchainType: wallet.token.blockchainType).birthdayHeight

        adapter.$zCashBalanceData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.zCashBalanceData = $0 }
            .store(in: &cancellables)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balanceHidden = $0
            })
            .disposed(by: disposeBag)
    }

    private func recreateAdapter(birthdayHeight: Int) {
        let blockchainType = wallet.token.blockchainType
        restoreSettingsService.set(birthdayHeight: birthdayHeight.description, account: wallet.account, blokcchainType: blockchainType)

        self.birthdayHeight = birthdayHeight

        adapterManager.recreateAdapter(blockchainType: blockchainType)
    }
}

extension ZcashWalletTokenViewModel {
    var ownAddress: String? {
        adapter.uAddress?.stringEncoded
    }

    func onChange(birthdayHeight: Int) {
        adapter
            .wipe()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                switch result {
                case .finished:
                    self?.recreateAdapter(birthdayHeight: birthdayHeight)
                case let .failure(error):
                    print("ZCash wipe has error!: \(error)")
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
