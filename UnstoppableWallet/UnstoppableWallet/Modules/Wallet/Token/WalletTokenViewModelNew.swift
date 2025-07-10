import Combine
import Foundation
import MarketKit
import RxSwift

class WalletTokenViewModelNew: ObservableObject {
    private let coinPriceService = WalletCoinPriceService()
    private let walletService: WalletService
    private let cloudBackupManager = Core.shared.cloudBackupManager
    private let balanceHiddenManager = Core.shared.balanceHiddenManager
    private let appManager = Core.shared.appManager

    private let disposeBag = DisposeBag()

    let wallet: Wallet

    @Published var balanceHidden: Bool
    @Published var isMainNet: Bool
    @Published var balanceData: BalanceData
    @Published var state: AdapterState
    @Published var priceItem: WalletCoinPriceService.Item?

    @Published var receivePresented = false

    init(wallet: Wallet) {
        self.wallet = wallet
        walletService = WalletServiceFactory().walletService(account: wallet.account)

        balanceHidden = balanceHiddenManager.balanceHidden
        isMainNet = walletService.isMainNet(wallet: wallet) ?? true
        balanceData = walletService.balanceData(wallet: wallet) ?? BalanceData(balance: 0)
        state = walletService.state(wallet: wallet) ?? .syncing(progress: nil, lastBlockDate: nil)
        priceItem = wallet.priceCoinUid.flatMap { coinPriceService.item(coinUid: $0) }

        walletService.delegate = self
        coinPriceService.delegate = self

        coinPriceService.set(coinUids: Set([wallet.priceCoinUid].compactMap { $0 }))

        subscribe(disposeBag, appManager.willEnterForegroundObservable) { [weak self] in
            self?.coinPriceService.refresh()
        }

        balanceHiddenManager.balanceHiddenObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.balanceHidden = $0
            })
            .disposed(by: disposeBag)
    }
}

extension WalletTokenViewModelNew: IWalletServiceDelegate {
    func didUpdateWallets(walletService _: WalletService) {}

    func didUpdate(wallets _: [Wallet], walletService _: WalletService) {
        // todo???
    }

    func didUpdate(isMainNet: Bool, wallet: Wallet) {
        guard wallet == self.wallet else {
            return
        }

        DispatchQueue.main.async {
            self.isMainNet = isMainNet
        }
    }

    func didUpdate(balanceData: BalanceData, wallet: Wallet) {
        guard wallet == self.wallet else {
            return
        }

        DispatchQueue.main.async {
            self.balanceData = balanceData
        }
    }

    func didUpdate(state: AdapterState, wallet: Wallet) {
        guard wallet == self.wallet else {
            return
        }

        DispatchQueue.main.async {
            self.state = state
        }
    }
}

extension WalletTokenViewModelNew: IWalletCoinPriceServiceDelegate {
    func didUpdate(itemsMap: [String: WalletCoinPriceService.Item]?) {
        guard let priceCoinUid = wallet.priceCoinUid, let itemsMap, let priceItem = itemsMap[priceCoinUid] else {
            return
        }

        DispatchQueue.main.async {
            self.priceItem = priceItem
        }
    }
}

extension WalletTokenViewModelNew {
    var title: String {
        var title = wallet.coin.code
        if let badge = wallet.badge {
            title += " (\(badge))"
        }
        return title
    }

    var buttons: [WalletButton] {
        if wallet.account.watchAccount {
            return [.address, .chart]
        } else {
            return [.send, .receive] + (AppConfig.swapEnabled && wallet.token.swappable ? [.swap] : []) + [.chart]
        }
    }

    func onTapReceive() {
        if wallet.account.backedUp || cloudBackupManager.backedUp(uniqueId: wallet.account.type.uniqueId()) {
            receivePresented = true
        } else {
            let wallet = wallet

            Coordinator.shared.present(type: .bottomSheet) { isPresented in
                BackupRequiredView.prompt(
                    account: wallet.account,
                    description: "receive_alert.not_backed_up_description".localized(wallet.account.name, wallet.coin.name),
                    isPresented: isPresented
                )
            }

            stat(page: .tokenPage, event: .open(page: .backupRequired))
        }
    }

    func onTapAmount() {
        balanceHiddenManager.toggleBalanceHidden()
    }
}
