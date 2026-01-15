import Combine
import Foundation
import HsExtensions
import MarketKit

class SendViewModel: ObservableObject {
    private let autoRefreshDuration: Double = 20

    private let currencyManager = Core.shared.currencyManager
    private let marketKit = Core.shared.marketKit
    private let recentAddressStorage = Core.shared.recentAddressStorage

    private var syncTask: AnyTask?
    private var ratesCancellable: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?

    let handler: ISendHandler?
    let transactionService: ITransactionService?
    let currency: Currency

    private let address: String?

    @Published var rates = [String: Decimal]()

    @Published var sendData: ISendData?
    @Published var sending = false
    @Published var transactionSettingsModified = false

    private var nextRefreshTime: Double?

    private let errorSubject = PassthroughSubject<String, Never>()

    @Published var state: State = .syncing {
        didSet {
            timer?.invalidate()
            nextRefreshTime = nil

            if case .success = state {
                let duration = handler?.expirationDuration.map { Double($0) } ?? autoRefreshDuration
                nextRefreshTime = Date().timeIntervalSince1970 + duration

                timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                    self?.sync(silent: true)
                }
            }
        }
    }

    init(sendData: SendData, address: String? = nil) {
        handler = SendHandlerFactory.handler(sendData: sendData)
        currency = currencyManager.baseCurrency
        self.address = address

        if let handler {
            transactionService = TransactionServiceFactory.transactionService(baseToken: handler.baseToken, initialTransactionSettings: handler.initialTransactionSettings)
        } else {
            transactionService = nil
        }

        transactionService?.updatePublisher
            .sink { [weak self] in
                self?.syncTransactionSettingsModified()
                self?.sync()
            }
            .store(in: &cancellables)

        handler?.refreshPublisher?
            .sink { [weak self] in
                self?.sync()
            }
            .store(in: &cancellables)

        sync()
    }

    var cautions: [CautionNew] {
        var cautions = transactionService?.cautions ?? []

        if let sendData, let baseToken = handler?.baseToken {
            cautions.append(contentsOf: sendData.cautions(baseToken: baseToken, currency: currency, rates: rates))
        }

        return cautions
    }

    var canSend: Bool {
        guard let sendData, sendData.canSend else {
            return false
        }

        if let service = transactionService, service.cautions.contains(where: { $0.type == .error }) {
            return false
        }

        return true
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

    @MainActor private func report(error: Error) {
        errorSubject.send(error.smartDescription)
    }
}

extension SendViewModel {
    var errorPublisher: AnyPublisher<String, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func stopAutoQuoting() {
        timer?.invalidate()
    }

    func autoQuoteIfRequired() {
        guard !state.isSyncing, let nextRefreshTime else {
            return
        }

        let now = Date().timeIntervalSince1970

        if now > nextRefreshTime {
            sync(silent: true)
        } else {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: nextRefreshTime - now, repeats: false) { [weak self] _ in
                self?.sync(silent: true)
            }
        }
    }

    func sync(silent: Bool = false) {
        guard let handler else {
            return
        }

        syncTask = nil

        if !state.isSyncing, !silent {
            state = .syncing
        }

        syncTask = Task { [weak self, handler, transactionService] in
            var sendData: ISendData?
            var state: State

            do {
                try await transactionService?.sync()

                let _sendData = try await handler.sendData(transactionSettings: transactionService?.transactionSettings)

                await self?.syncRates(coins: [handler.baseToken.coin] + _sendData.rateCoins)

                sendData = _sendData
                state = .success
            } catch {
                state = .failed(error: error)
            }

            if !Task.isCancelled {
                await MainActor.run { [weak self, sendData, state] in
                    self?.sendData = sendData
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

            guard let sendData else {
                throw SendError.noSendData
            }

            await set(sending: true)

            _ = try await handler.send(data: sendData)

            if let address {
                try? recentAddressStorage.save(address: address, blockchainUid: handler.baseToken.blockchain.uid)
            }
        } catch {
            await set(sending: false)
            await report(error: error)
            throw error
        }
    }
}

extension SendViewModel {
    enum State {
        case syncing
        case success
        case failed(error: Error)

        var isSyncing: Bool {
            switch self {
            case .syncing: return true
            default: return false
            }
        }

        var isSuccess: Bool {
            switch self {
            case .success: return true
            default: return false
            }
        }
    }

    enum SendError: Error {
        case noHandler
        case noSendData
    }
}
