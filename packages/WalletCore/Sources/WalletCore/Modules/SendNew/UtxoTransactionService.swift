import BitcoinCore
import Combine
import MarketKit
import SwiftUI

class UtxoTransactionService: TransactionService {
    override class func instance(sendData: SendData, baseToken: Token, initialTransactionSettings _: InitialTransactionSettings?) -> ITransactionService? {
        if case .bitcoinResend = sendData {
            return nil
        }
        guard BtcBlockchainManager.blockchainTypes.contains(baseToken.blockchainType),
              let adapter = Core.shared.adapterManager.adapter(for: baseToken) as? BitcoinBaseAdapter
        else { return nil }
        return UtxoTransactionService(blockchainType: baseToken.blockchainType, adapter: adapter)
    }

    private let blockchainType: BlockchainType
    private let adapter: BitcoinBaseAdapter
    private let feeRateProvider: IFeeRateProvider?

    private(set) var actualFeeRates: FeeRateProvider.FeeRates?
    private var satoshiPerByte: Int? {
        didSet {
            validate()
        }
    }

    private(set) var cautions: [CautionNew] = []
    private let updateSubject = PassthroughSubject<Void, Never>()

    init(blockchainType: BlockchainType, adapter: BitcoinBaseAdapter) {
        self.blockchainType = blockchainType
        self.adapter = adapter
        feeRateProvider = Core.shared.feeRateProviderFactory.provider(blockchainType: blockchainType)
    }

    private func validate() {
        cautions = Self.validate(actualFeeRates: actualFeeRates, satoshiPerByte: satoshiPerByte)
    }
}

extension UtxoTransactionService: ITransactionService {
    var transactionSettings: TransactionSettings? {
        guard let currentSatoshiPerByte else {
            return nil
        }

        return .bitcoin(satoshiPerByte: currentSatoshiPerByte)
    }

    var modified: Bool {
        satoshiPerByte != nil
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    func sync() async throws {
        let feeRates = try await feeRateProvider?.feeRates()

        // Syncs can overlap and run off the main actor, while the UI reads this on it.
        try await MainActor.run {
            // Checked in the same turn as the commit, so a superseded sync cannot overwrite a newer one.
            try Task.checkCancellation()

            actualFeeRates = feeRates
        }
    }
}

extension UtxoTransactionService {
    var recommendedSatoshiPerByte: Int? {
        actualFeeRates?.recommended
    }

    var currentSatoshiPerByte: Int? {
        satoshiPerByte ?? recommendedSatoshiPerByte
    }

    func resolveFee(params: SendParameters, satoshiPerByte: Int?) throws -> Decimal {
        let params = params.copy()
        params.feeRate = satoshiPerByte
        return try adapter.sendInfo(params: params).fee
    }

    func set(satoshiPerByte: Int?) {
        self.satoshiPerByte = satoshiPerByte
        updateSubject.send()
    }
}

extension UtxoTransactionService {
    static func validate(actualFeeRates: FeeRateProvider.FeeRates?, satoshiPerByte: Int?) -> [CautionNew] {
        guard let actualFeeRates, let satoshiPerByte else {
            return []
        }

        if actualFeeRates.minimum > satoshiPerByte {
            return [.init(title: "send.fee_settings.fee_error.title".localized, text: "send.fee_settings.too_low".localized, type: .error)]
        }

        if actualFeeRates.recommended > satoshiPerByte {
            return [.init(title: "send.fee_settings.stuck_warning.title".localized, text: "send.fee_settings.stuck_warning".localized, type: .warning)]
        }

        return []
    }
}
