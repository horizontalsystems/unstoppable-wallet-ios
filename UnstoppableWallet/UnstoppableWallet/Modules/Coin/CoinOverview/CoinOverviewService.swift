import UIKit
import RxSwift
import RxCocoa
import MarketKit
import CurrencyKit
import LanguageKit
import HsExtensions

class CoinOverviewService {
    private var tasks = Set<AnyTask>()

    private let coinUid: String
    private let marketKit: MarketKit.Kit
    private let currencyKit: CurrencyKit.Kit
    private let languageManager: LanguageManager
    private let accountManager: AccountManager
    private let walletManager: WalletManager

    private let stateRelay = PublishRelay<DataStatus<Item>>()
    private(set) var state: DataStatus<Item> = .loading {
        didSet {
            stateRelay.accept(state)
        }
    }

    init(coinUid: String, marketKit: MarketKit.Kit, currencyKit: CurrencyKit.Kit, languageManager: LanguageManager, accountManager: AccountManager, walletManager: WalletManager) {
        self.coinUid = coinUid
        self.marketKit = marketKit
        self.currencyKit = currencyKit
        self.languageManager = languageManager
        self.accountManager = accountManager
        self.walletManager = walletManager
    }

    private func sync(info: MarketInfoOverview) {
        let account = accountManager.activeAccount

        let tokens = info.fullCoin.tokens
                .filter {
                    switch $0.type {
                    case .unsupported(_, let reference): return reference != nil
                    default: return true
                    }
                }

        let walletTokens = walletManager.activeWallets.map { $0.token }

        let tokenItems = tokens
                .sorted { lhsToken, rhsToken in
                    let lhsTypeOrder = lhsToken.type.order
                    let rhsTypeOrder = rhsToken.type.order

                    guard lhsTypeOrder == rhsTypeOrder else {
                        return lhsTypeOrder < rhsTypeOrder
                    }

                    return lhsToken.blockchainType.order < rhsToken.blockchainType.order
                }
                .map { token in
                    let state: TokenItemState

                    if let account = account, !account.watchAccount, account.type.supports(token: token) {
                        if walletTokens.contains(token) {
                            state = .alreadyAdded
                        } else {
                            state = .canBeAdded
                        }
                    } else {
                        state = .cannotBeAdded
                    }

                    return TokenItem(
                            token: token,
                            state: state
                    )
                }

        state = .completed(Item(info: info, tokens: tokenItems, guideUrl: guideUrl))
    }

    private var guideUrl: URL? {
        guard let guideFileUrl = guideFileUrl else {
            return nil
        }

        return URL(string: guideFileUrl, relativeTo: AppConfig.guidesIndexUrl)
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
        tasks = Set()

        state = .loading

        Task { [weak self, marketKit, coinUid, currencyKit, languageManager] in
            do {
                let info = try await marketKit.marketInfoOverview(coinUid: coinUid, currencyCode: currencyKit.baseCurrency.code, languageCode: languageManager.currentLanguage)
                self?.sync(info: info)
            } catch {
                self?.state = .failed(error)
            }
        }.store(in: &tasks)
    }

    func editWallet(index: Int, add: Bool) throws {
        guard case .completed(let item) = state else {
            throw EditWalletError.invalidState
        }

        guard let account = accountManager.activeAccount else {
            throw EditWalletError.noActiveAccount
        }

        let token = item.tokens[index].token

        let wallet = Wallet(token: token, account: account)

        if add {
            walletManager.save(wallets: [wallet])
        } else {
            walletManager.delete(wallets: [wallet])
        }

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
        let token: Token
        let state: TokenItemState
    }

    enum TokenItemState {
        case canBeAdded
        case alreadyAdded
        case cannotBeAdded
    }

    enum EditWalletError: Error {
        case invalidState
        case noActiveAccount
    }

}
