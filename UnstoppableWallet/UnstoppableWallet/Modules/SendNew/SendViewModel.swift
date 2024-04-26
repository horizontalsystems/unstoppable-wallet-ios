import Combine
import Foundation
import HsExtensions
import MarketKit

class SendViewModel: ObservableObject {
    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit

    private var syncTask: AnyTask?
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    let handler: ISendHandler?
    let transactionService: ITransactionService?
    let feeToken: Token?
    let currency: Currency

    @Published var feeTokenRate: Decimal?
    @Published var sending = false
    @Published var transactionSettingsModified = false
    @Published var timeLeft: Int = 0

    let errorSubject = PassthroughSubject<String, Never>()

    @Published var state: State = .syncing {
        didSet {
            timer?.cancel()

            if let handler, let data = state.data, data.canSend {
                timeLeft = handler.expirationDuration

                timer = Timer.publish(every: 1, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.handleTimerTick()
                    }
            }
        }
    }

    init(handler: ISendHandler?) {
        self.handler = handler

        if let handler {
            transactionService = TransactionServiceFactory.transactionService(blockchainType: handler.blockchainType)
            feeToken = try? marketKit.token(query: TokenQuery(blockchainType: handler.blockchainType, tokenType: .native))
        } else {
            transactionService = nil
            feeToken = nil
        }

        currency = currencyManager.baseCurrency

        transactionService?.updatePublisher
            .sink { [weak self] in
                self?.syncTransactionSettingsModified()
                self?.sync()
            }
            .store(in: &cancellables)

        if let feeToken {
            feeTokenRate = marketKit.coinPrice(coinUid: feeToken.coin.uid, currencyCode: currency.code)?.value
            marketKit.coinPricePublisher(coinUid: feeToken.coin.uid, currencyCode: currency.code)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] price in self?.feeTokenRate = price.value }
                .store(in: &cancellables)
        }

        sync()
    }

    private func handleTimerTick() {
        timeLeft -= 1

        if timeLeft == 0 {
            timer?.cancel()
        }
    }

    private func syncTransactionSettingsModified() {
        transactionSettingsModified = transactionService?.modified ?? false
    }

    @MainActor private func set(sending: Bool) {
        self.sending = sending
    }
}

extension SendViewModel {
    func sync() {
        guard let handler, let transactionService else {
            return
        }

        syncTask = nil

        if !state.isSyncing {
            state = .syncing
        }

        syncTask = Task { [weak self, handler, transactionService] in
            var state: State

            do {
                try await transactionService.sync()

                let data = try await handler.confirmationData(transactionSettings: transactionService.transactionSettings)
                state = .success(data: data)
            } catch {
                state = .failed(error: error)
            }

            if !Task.isCancelled {
                await MainActor.run { [weak self, state] in
                    self?.state = state
                }
            }
        }
        .erased()
    }

    func send() async throws {
        do {
            guard let handler else {
                throw SendError.noHandler
            }

            guard let data = state.data else {
                throw SendError.noData
            }

            await set(sending: true)

            try await handler.send(data: data)
        } catch {
            await set(sending: false)
            errorSubject.send(error.smartDescription)
            throw error
        }
    }
}

extension SendViewModel {
    enum State {
        case syncing
        case success(data: ISendConfirmationData)
        case failed(error: Error)

        var data: ISendConfirmationData? {
            switch self {
            case let .success(data): return data
            default: return nil
            }
        }

        var isSyncing: Bool {
            switch self {
            case .syncing: return true
            default: return false
            }
        }
    }

    enum SendError: Error {
        case noHandler
        case noData
    }
}
