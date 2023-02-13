import UIKit
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit
import LanguageKit

class CoinOverviewService {
    private var disposeBag = DisposeBag()

    private let coinUid: String
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let languageManager: LanguageManager
    private let appConfigProvider: AppConfigProvider
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinUid: String, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, languageManager: LanguageManager, appConfigProvider: AppConfigProvider, accountManager: AccountManager, walletManager: WalletManager) {
        self.coinUid = coinUid
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.languageManager = languageManager
        self.appConfigProvider = appConfigProvider
        self.accountManager = accountManager
        self.walletManager = walletManager
    }

    private func sync(info: MarketInfoOverview) {
        let account = accountManager.activeAccount

        let configuredTokens = info.fullCoin.tokens
                .map { $0.configuredTokens }
                .flatMap { $0 }
                .filter {
                    switch $0.token.type {
                    case .unsupported(_, let reference): return reference != nil
                    default: return true
                    }
                }

        let walletConfiguredTokens = walletManager.activeWallets.map { $0.configuredToken }

        let tokenItems = configuredTokens
                .sorted { lhsConfiguredToken, rhsConfiguredToken in
                    let lhsTypeOrder = lhsConfiguredToken.token.type.order
                    let rhsTypeOrder = rhsConfiguredToken.token.type.order

                    guard lhsTypeOrder == rhsTypeOrder else {
                        return lhsTypeOrder < rhsTypeOrder
                    }

                    let lhsOrder = lhsConfiguredToken.blockchainType.order
                    let rhsOrder = rhsConfiguredToken.blockchainType.order

                    if lhsOrder != rhsOrder {
                        return lhsOrder < rhsOrder
                    }

                    return lhsConfiguredToken.coinSettings.order < rhsConfiguredToken.coinSettings.order
                }
                .map { configuredToken in
                    let state: TokenItemState

                    if let account = account, account.type.supports(configuredToken: configuredToken) {
                        if walletConfiguredTokens.contains(configuredToken) {
                            state = .alreadyAdded
                        } else {
                            state = .supported
                        }
                    } else {
                        state = .notSupported
                    }

                    return TokenItem(
                            configuredToken: configuredToken,
                            state: state
                    )
                }

        state = .completed(Item(info: info, tokens: tokenItems, guideUrl: guideUrl))
    }

    private var guideUrl: URL? {
        guard let guideFileUrl = guideFileUrl else {
            return nil
        }

        return URL(string: guideFileUrl, relativeTo: appConfigProvider.guidesIndexUrl)
    }

    private var guideFileUrl: String? {
        switch coinUid {
        case "bitcoin": return "guides/token_guides/en/bitcoin.md"
        case "ethereum": return "guides/token_guides/en/ethereum.md"
        case "bitcoin-cash": return "guides/token_guides/en/bitcoin-cash.md"
        case "zcash": return "guides/token_guides/en/zcash.md"
        case "uniswap": return "guides/token_guides/en/uniswap.md"
        case "curve-dao-token": return "guides/token_guides/en/curve-finance.md"
        case "balancer": return "guides/token_guides/en/balancer-dex.md"
        case "synthetix-network-token": return "guides/token_guides/en/synthetix.md"
        case "tether": return "guides/token_guides/en/tether.md"
        case "maker": return "guides/token_guides/en/makerdao.md"
        case "dai": return "guides/token_guides/en/makerdao.md"
        case "aave": return "guides/token_guides/en/aave.md"
        case "compound": return "guides/token_guides/en/compound.md"
        default: return nil
        }
    }

}

extension CoinOverviewService {

    var stateObservable: Observable<DataStatus<Item>> {
        stateRelay.asObservable()
    }

    var currency: Currency {
        currencyKit.baseCurrency
    }

    func sync() {
        disposeBag = DisposeBag()

        state = .loading

        marketKit.marketInfoOverviewSingle(coinUid: coinUid, currencyCode: currencyKit.baseCurrency.code, languageCode: languageManager.currentLanguage)
                .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                .subscribe(onSuccess: { [weak self] info in
                    self?.sync(info: info)
                }, onError: { [weak self] error in
                    self?.state = .failed(error)
                })
                .disposed(by: disposeBag)
    }

    func addToWallet(index: Int) throws {
        guard case .completed(let item) = state else {
            throw AddToWalletError.invalidState
        }

        guard let account = accountManager.activeAccount else {
            throw AddToWalletError.noActiveAccount
        }

        let configuredToken = item.tokens[index].configuredToken

        let wallet = Wallet(configuredToken: configuredToken, account: account)
        walletManager.save(wallets: [wallet])

        sync(info: item.info)
    }

}

extension CoinOverviewService {

    struct Item {
        let info: MarketInfoOverview
        let tokens: [TokenItem]
        let guideUrl: URL?
    }

    struct TokenItem {
        let configuredToken: ConfiguredToken
        let state: TokenItemState
    }

    enum TokenItemState {
        case notSupported
        case supported
        case alreadyAdded
    }

    enum AddToWalletError: Error {
        case invalidState
        case noActiveAccount
    }

}
