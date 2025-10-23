import Combine
import Foundation
import MarketKit
import RxSwift

class WalletViewModel: WalletListViewModel {
    private let balanceConversionManager = Core.shared.balanceConversionManager
    private let walletButtonHiddenManager = Core.shared.walletButtonHiddenManager
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private let appManager = Core.shared.appManager
    private let eventHandler = Core.shared.appEventHandler
    private let rateAppManager = Core.shared.rateAppManager

    @Published private(set) var buttonHidden: Bool
    @Published private(set) var totalItem: TotalItem

    override init() {
        buttonHidden = walletButtonHiddenManager.buttonHidden
        totalItem = .init(currencyValue: .init(currency: .init(code: "", symbol: "", decimal: 0), value: 0), state: .synced, convertedValue: nil, convertedValueExpired: false)

        super.init()

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }

        balanceConversionManager.$conversionToken
            .sink { [weak self] _ in self?.syncTotalItem() }
            .store(in: &cancellables)

        walletButtonHiddenManager.buttonHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.buttonHidden = $0
            })
            .disposed(by: disposeBag)
    }

    private func syncTotalItem() {
        queue.async {
            self._syncTotalItem()
        }
    }

    override var conversionCoinUids: Set<String> {
        Set(balanceConversionManager.conversionTokens.map(\.coin.uid))
    }

    override func _syncTotalItem() {
        var total: Decimal = 0
        var expired = false
        var syncing = false

        for item in __items {
            if let rateItem = item.priceItem {
                total += item.balanceData.total * rateItem.price.value

                if item.state.syncing {
                    syncing = true
                }

                if rateItem.expired {
                    expired = true
                }
            }

            if case .synced = item.state {
                // do nothing
            } else {
                expired = true
            }
        }

        var convertedValue: AppValue?
        var convertedValueExpired = false

        if let conversionToken = balanceConversionManager.conversionToken, let priceItem = coinPriceService.item(coinUid: conversionToken.coin.uid) {
            convertedValue = AppValue(token: conversionToken, value: total / priceItem.price.value)
            convertedValueExpired = priceItem.expired
        }

        let state: ValueState
        if syncing {
            state = .syncing
        } else if expired {
            state = .expired
        } else {
            state = .synced
        }

        let totalItem = TotalItem(
            currencyValue: CurrencyValue(currency: coinPriceService.currency, value: total),
            state: state,
            convertedValue: convertedValue,
            convertedValueExpired: expired || convertedValueExpired
        )

        DispatchQueue.main.async {
            self.totalItem = totalItem
        }
    }
}

extension WalletViewModel {
    var buttons: [WalletButton] {
        [.scan, .receive, .send] + (AppConfig.swapEnabled ? [.swap] : [])
    }

    func verifyBackedUp() -> Bool {
        guard let account else {
            return false
        }

        let backedUp = account.backedUp || cloudBackupManager.backedUp(uniqueId: account.type.uniqueId())
        if !backedUp {
            showBackupBottomSheet()
        }

        return backedUp
    }

    func onAppear() {
        rateAppManager.onBalancePageAppear()
    }

    func onDisappear() {
        rateAppManager.onBalancePageDisappear()
    }

    func onTapAmount() {
        balanceHiddenManager.toggleBalanceHidden()
    }

    func onTapConvertedAmount() {
        balanceConversionManager.toggleConversionToken()
    }

    func showBackupBottomSheet() {
        guard let account else {
            return
        }

        Coordinator.shared.present(type: .bottomSheet) { isPresented in
            BackupRequiredView.prompt(
                account: account,
                description: "receive_alert.any_coins.not_backed_up_description".localized(account.name),
                isPresented: isPresented
            )
        }

        stat(page: .balance, event: .open(page: .backupRequired))
    }

    func onTapReceive() {
        guard let account else {
            return
        }

        guard verifyBackedUp() else {
            return
        }

        Coordinator.shared.present { _ in
            ReceiveCoinListView(account: account)
        }
        stat(page: .balance, event: .open(page: .receiveTokenList))
    }

    func onDisable(wallet: Wallet) {
        walletService?.disable(wallet: wallet)
    }

    func refresh() async {
        walletService?.refresh()
        coinPriceService.refresh()

        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func process(scanned: String) {
        Task { [eventHandler] in
            try await eventHandler.handle(source: StatPage.balance, event: scanned.trimmingCharacters(in: .whitespacesAndNewlines), eventType: [.walletConnectUri, .address])
        }
    }
}

extension WalletViewModel {
    struct TotalItem {
        let currencyValue: CurrencyValue
        let state: ValueState
        let convertedValue: AppValue?
        let convertedValueExpired: Bool
    }

    enum ValueState {
        case synced
        case syncing
        case expired
    }
}
