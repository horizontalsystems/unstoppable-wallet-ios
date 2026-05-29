import Combine
import Foundation
import MarketKit

class AddTokenViewModel: ObservableObject {
    private let account: Account
    private let items: [AddTokenModule.Item]
    private let coinManager: CoinManager
    private let walletManager: WalletManager

    private var fetchTask: Task<Void, Never>?

    @Published private(set) var state: State = .idle
    @Published private(set) var currentBlockchainItem: CurrentBlockchainItem
    @Published var reference: String = ""

    private var cancellables = Set<AnyCancellable>()

    private let finishSubject = PassthroughSubject<Void, Never>()
    var finishPublisher: AnyPublisher<Void, Never> {
        finishSubject.eraseToAnyPublisher()
    }

    init(account: Account, items: [AddTokenModule.Item], coinManager: CoinManager, walletManager: WalletManager) {
        let sortedItems = items.sorted(by: { $0.blockchain.type.order < $1.blockchain.type.order })

        self.account = account
        self.items = sortedItems
        self.coinManager = coinManager
        self.walletManager = walletManager

        currentBlockchainItem = CurrentBlockchainItem(item: sortedItems[0])

        $reference
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.syncState()
            }
            .store(in: &cancellables)
    }

    private func syncState() {
        fetchTask?.cancel()
        fetchTask = nil

        let trimmed = reference.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        let service = items.by(currentBlockchainItem.blockchain).service

        do {
            try service.validate(reference: trimmed)
        } catch {
            state = .failed(error: error)
            return
        }

        let tokenQuery = service.tokenQuery(reference: trimmed)

        if let existingToken = try? coinManager.token(query: tokenQuery) {
            state = .alreadyExists(token: existingToken)
            return
        }

        state = .loading

        fetchTask = Task { [weak self, service, trimmed] in
            do {
                let token = try await service.token(reference: trimmed)
                await MainActor.run { [weak self] in self?.state = .fetched(token: token) }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run { [weak self] in self?.state = .failed(error: error) }
                }
            }
        }
    }
}

extension AddTokenViewModel {
    var canAddToken: Bool {
        account.type.canAddTokens
    }

    var blockchains: [Blockchain] {
        items.map(\.blockchain)
    }

    var placeholder: String {
        currentBlockchainItem.placeholder
    }

    var loading: Bool {
        if case .loading = state { return true }
        return false
    }

    var buttonEnabled: Bool {
        if case .fetched = state { return true }
        return false
    }

    var cautionState: CautionState {
        switch state {
        case .alreadyExists:
            return .caution(Caution(text: "add_token.already_added".localized, type: .warning))
        case let .failed(error):
            return .caution(Caution(text: error.convertedError.localizedDescription, type: .error))
        default:
            return .none
        }
    }

    var viewItem: ViewItem? {
        switch state {
        case let .alreadyExists(token):
            return ViewItem(name: token.coin.name, code: token.coin.code, decimals: String(token.decimals))
        case let .fetched(token):
            return ViewItem(name: token.coin.name, code: token.coin.code, decimals: String(token.decimals))
        default:
            return nil
        }
    }

    func set(blockchain: Blockchain) {
        currentBlockchainItem = CurrentBlockchainItem(item: items.by(blockchain))
        syncState()
    }

    func save() {
        guard case let .fetched(token) = state else {
            return
        }

        let wallet = Wallet(token: token, account: account)
        walletManager.save(wallets: [wallet])

        stat(page: .addToken, event: .addToken(token: token))
        finishSubject.send()
    }
}

extension AddTokenViewModel {
    enum State {
        case idle
        case loading
        case alreadyExists(token: Token)
        case fetched(token: Token)
        case failed(error: Error)
    }

    struct ViewItem {
        let name: String
        let code: String
        let decimals: String

        var fields: [(String, String)] {
            [
                ("add_token.coin_name".localized, name),
                ("add_token.symbol".localized, code),
                ("add_token.decimals".localized, decimals),
            ]
        }
    }

    struct CurrentBlockchainItem {
        let blockchain: Blockchain
        let placeholder: String

        init(item: AddTokenModule.Item) {
            blockchain = item.blockchain
            placeholder = item.service.placeholder
        }
    }
}
