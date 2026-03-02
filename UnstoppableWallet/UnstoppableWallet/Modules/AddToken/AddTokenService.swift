import Foundation
import MarketKit

protocol IAddTokenBlockchainService {
    var placeholder: String { get }
    func validate(reference: String) throws
    func tokenQuery(reference: String) -> TokenQuery
    func token(reference: String) async throws -> Token
}

// class AddTokenService {
//     private let account: Account
//     private let items: [AddTokenModule.Item]
//     private let coinManager: CoinManager
//     private let walletManager: WalletManager
//
//     private var fetchTask: Task<Void, Never>?
//
//     private let stateRelay = PublishRelay<State>()
//     private(set) var state: State = .idle {
//         didSet {
//             stateRelay.accept(state)
//         }
//     }
//
//     private let currentBlockchainItemRelay = PublishRelay<CurrentBlockchainItem>()
//     private(set) var currentBlockchainItem: CurrentBlockchainItem {
//         didSet {
//             currentBlockchainItemRelay.accept(currentBlockchainItem)
//         }
//     }
//
//     private var currentIndex: Int = 0
//     private var currentReference: String?
//
//     init(account: Account, items: [AddTokenModule.Item], coinManager: CoinManager, walletManager: WalletManager) {
//         let sortedItems = items.sorted(by: { $0.blockchain.type.order < $1.blockchain.type.order })
//
//         self.account = account
//         self.items = sortedItems
//         self.coinManager = coinManager
//         self.walletManager = walletManager
//
//         currentBlockchainItem = CurrentBlockchainItem(item: sortedItems[0])
//     }
//
//     private func syncState() {
//         fetchTask?.cancel()
//         fetchTask = nil
//
//         guard let reference = currentReference, !reference.isEmpty else {
//             state = .idle
//             return
//         }
//
//         let service = items[currentIndex].service
//
//         do {
//             try service.validate(reference: reference)
//         } catch {
//             state = .failed(error: error)
//             return
//         }
//
//         let tokenQuery = service.tokenQuery(reference: reference)
//
//         if let existingToken = try? coinManager.token(query: tokenQuery) {
//             state = .alreadyExists(token: existingToken)
//             return
//         }
//
//         state = .loading
//
//         fetchTask = Task { [weak self, service, reference] in
//             do {
//                 let token = try await service.token(reference: reference)
//                 self?.state = .fetched(token: token)
//             } catch {
//                 if !Task.isCancelled {
//                     self?.state = .failed(error: error)
//                 }
//             }
//         }
//     }
// }
//
// extension AddTokenService {
//     var stateObservable: Observable<State> {
//         stateRelay.asObservable()
//     }
//
//     var currentBlockchainItemObservable: Observable<CurrentBlockchainItem> {
//         currentBlockchainItemRelay.asObservable()
//     }
//
//     var blockchainItems: [BlockchainItem] {
//         items.enumerated().map { index, item in
//             BlockchainItem(blockchain: item.blockchain, current: index == currentIndex)
//         }
//     }
//
//     func setBlockchain(index: Int) {
//         currentIndex = index
//         currentBlockchainItem = CurrentBlockchainItem(item: items[index])
//         syncState()
//     }
//
//     func set(reference: String?) {
//         currentReference = reference
//         syncState()
//     }
//
//     func save() {
//         guard case let .fetched(token) = state else {
//             return
//         }
//
//         let wallet = Wallet(token: token, account: account)
//         walletManager.save(wallets: [wallet])
//
//         stat(page: .addToken, event: .addToken(token: token))
//     }
// }
//
// extension AddTokenService {
//     enum State {
//         case idle
//         case loading
//         case alreadyExists(token: Token)
//         case fetched(token: Token)
//         case failed(error: Error)
//     }
//
//     struct BlockchainItem {
//         let blockchain: Blockchain
//         let current: Bool
//     }
//
//     struct CurrentBlockchainItem {
//         let blockchain: Blockchain
//         let placeholder: String
//
//         init(item: AddTokenModule.Item) {
//             blockchain = item.blockchain
//             placeholder = item.service.placeholder
//         }
//     }
// }
