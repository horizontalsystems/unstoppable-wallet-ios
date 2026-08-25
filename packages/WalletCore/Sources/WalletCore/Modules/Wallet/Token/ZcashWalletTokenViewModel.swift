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
    @Published var ironwoodActive: Bool
    @Published private(set) var wiping = false

    init(adapter: ZcashAdapter, wallet: Wallet) {
        self.adapter = adapter
        self.wallet = wallet
        zCashBalanceData = adapter.zCashBalanceData
        balanceHidden = balanceHiddenManager.balanceHidden
        ironwoodActive = adapter.isIronwoodActive

        birthdayHeight = restoreSettingsService.settings(accountId: wallet.account.id, blockchainType: wallet.token.blockchainType).birthdayHeight

        adapter.zCashBalanceDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.zCashBalanceData = $0 }
            .store(in: &cancellables)

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balanceHidden = $0
            })
            .disposed(by: disposeBag)

        adapter.balanceStateUpdatedObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.ironwoodActive = self?.adapter.isIronwoodActive ?? false
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
        // Single-flight: a second wipe while one is running is silently dropped by the
        // SDK's hook set (its Hook equality ignores the payload), leaving a publisher
        // that never completes — and two concurrent doWipe calls race on the same files.
        guard !wiping else {
            return
        }
        // The stored adapter goes stale after a recreate; wiping through it would delete
        // the databases out from under the freshly created live adapter.
        guard let adapter = adapterManager.adapter(for: wallet) as? ZcashAdapter, !adapter.isPreparing else {
            return
        }

        wiping = true
        adapter
            .wipe()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                self?.wiping = false
                switch result {
                case .finished:
                    self?.recreateAdapter(birthdayHeight: birthdayHeight)
                case let .failure(error):
                    HudHelper.instance.show(banner: .error(string: error.smartDescription))
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
}
