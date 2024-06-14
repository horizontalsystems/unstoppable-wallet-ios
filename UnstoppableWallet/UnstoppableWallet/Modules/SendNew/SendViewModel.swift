import Combine
import Foundation
import HsExtensions
import MarketKit

class SendViewModel: ObservableObject {
    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit

    private var syncTask: AnyTask?
    private var timer: AnyCancellable?
    private var ratesCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    let handler: ISendHandler?
    let transactionService: ITransactionService?
    let currency: Currency

    @Published var rates = [String: Decimal]()

    @Published var sending = false
    @Published var transactionSettingsModified = false
    @Published var timeLeft: Int = 0

    let errorSubject = PassthroughSubject<String, Never>()

    @Published var state: State = .syncing {
        didSet {
            timer?.cancel()

            if let handler, let expirationDuration = handler.expirationDuration, let data = state.data, data.canSend {
                timeLeft = expirationDuration

                timer = Timer.publish(every: 1, on: .main, in: .common)
                    .autoconnect()
                    .sink { [weak self] _ in
                        self?.handleTimerTick()
                    }
            }
        }
    }

    var cautions: [CautionNew] {
        var cautions = transactionService?.cautions ?? []

        if let data = state.data, let baseToken = handler?.baseToken {
            cautions.append(contentsOf: data.cautions(baseToken: baseToken))
        }

        return cautions
    }

    var canSend: Bool {
        guard let data = state.data, data.canSend else {
            return false
        }

        if let service = transactionService, service.cautions.contains(where: { $0.type == .error }) {
            return false
        }

        return true
    }

    init(sendData: SendData) {
        handler = SendHandlerFactory.handler(sendData: sendData)
        currency = currencyManager.baseCurrency

        if let handler {
            transactionService = TransactionServiceFactory.transactionService(blockchainType: handler.baseToken.blockchainType, initialTransactionSettings: handler.initialTransactionSettings)
        } else {
            transactionService = nil
        }

        transactionService?.updatePublisher
            .sink { [weak self] in
                self?.syncTransactionSettingsModified()
                self?.sync()
            }
            .store(in: &cancellables)

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

    @MainActor private func syncRates(coins: [Coin]) {
        let coinUids = Array(Set(coins)).map(\.uid)

        rates = marketKit.coinPriceMap(coinUids: coinUids, currencyCode: currency.code).mapValues { $0.value }
        ratesCancellable = marketKit.coinPriceMapPublisher(coinUids: coinUids, currencyCode: currency.code)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rates in self?.rates = rates.mapValues { $0.value } }
    }

    @MainActor private func set(sending: Bool) {
        self.sending = sending
    }
}

extension SendViewModel {
    func sync() {
        guard let handler else {
            return
        }

        syncTask = nil

        if !state.isSyncing {
            state = .syncing
        }

        syncTask = Task { [weak self, handler, transactionService] in
            var state: State

            do {
                try await transactionService?.sync()

                let data = try await handler.sendData(transactionSettings: transactionService?.transactionSettings)

                await self?.syncRates(coins: [handler.baseToken.coin] + data.rateCoins)

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

            _ = try await handler.send(data: data)
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
        case success(data: ISendData)
        case failed(error: Error)

        var data: ISendData? {
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
