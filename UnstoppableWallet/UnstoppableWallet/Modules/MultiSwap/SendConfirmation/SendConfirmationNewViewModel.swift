import Combine
import Foundation
import HsExtensions
import MarketKit

class SendConfirmationNewViewModel: ObservableObject {
    private let currencyManager = App.shared.currencyManager
    private let marketKit = App.shared.marketKit
    private let transactionServiceFactory = TransactionServiceFactory()
    private let sendHandlerFactory = SendHandlerFactory()

    private var syncTask: AnyTask?
    private var sendTask: AnyTask?
    private var cancellables = Set<AnyCancellable>()

    let handler: ISendHandler?
    let transactionService: ITransactionService?
    let currency: Currency
    let feeToken: Token?

    @Published var feeTokenRate: Decimal?

    @Published var data: ISendConfirmationData?
    @Published var syncing = false
    @Published var sending = false

    let finishSubject = PassthroughSubject<Void, Never>()

    init(sendData: SendDataNew) {
        handler = sendHandlerFactory.handler(sendData: sendData)
        currency = currencyManager.baseCurrency

        if let handler {
            transactionService = transactionServiceFactory.transactionService(blockchainType: handler.blockchainType)
            feeToken = try? marketKit.token(query: TokenQuery(blockchainType: handler.blockchainType, tokenType: .native))
        } else {
            transactionService = nil
            feeToken = nil
        }

        transactionService?.updatePublisher
            .sink { [weak self] in self?.sync() }
            .store(in: &cancellables)

        if let feeToken {
            feeTokenRate = marketKit.coinPrice(coinUid: feeToken.coin.uid, currencyCode: currency.code)?.value
            marketKit.coinPricePublisher(tag: "send", coinUid: feeToken.coin.uid, currencyCode: currency.code)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] price in self?.feeTokenRate = price.value }
                .store(in: &cancellables)
        }

        sync()
    }
}

extension SendConfirmationNewViewModel {
    func sync() {
        guard let handler, let transactionService else {
            return
        }

        syncTask = nil
        data = nil

        if !syncing {
            syncing = true
        }

        syncTask = Task { [weak self, handler, transactionService] in
            try await transactionService.sync()

            let data = try await handler.confirmationData(transactionSettings: transactionService.transactionSettings)

            if !Task.isCancelled {
                await MainActor.run { [weak self, data] in
                    self?.syncing = false
                    self?.data = data
                }
            }
        }
        .erased()
    }

    func send() {
        guard let handler, let data else {
            return
        }

        sending = true

        sendTask = Task { [weak self, handler] in
            do {
                try await handler.send(data: data)

                await MainActor.run { [weak self] in
                    self?.finishSubject.send()
                }
            } catch {
                await MainActor.run { [weak self] in
                    self?.sending = false
                }
            }
        }
        .erased()
    }
}
