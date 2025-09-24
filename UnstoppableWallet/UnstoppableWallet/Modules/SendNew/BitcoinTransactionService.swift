import Combine
import MarketKit
import SwiftUI

class BitcoinTransactionService: ITransactionService {
    private let blockchainType: BlockchainType
    private let feeRateProvider: IFeeRateProvider?

    private(set) var usingRecommended: Bool = true
    private(set) var actualFeeRates: FeeRateProvider.FeeRates?
    private(set) var cautions: [CautionNew] = []
    private(set) var satoshiPerByte: Int? {
        didSet {
            validate()
        }
    }

    private let updateSubject = PassthroughSubject<Void, Never>()

    var transactionSettings: TransactionSettings? {
        guard let satoshiPerByte else {
            return nil
        }

        return .bitcoin(satoshiPerByte: satoshiPerByte)
    }

    var modified: Bool {
        !usingRecommended
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    init(blockchainType: BlockchainType) {
        self.blockchainType = blockchainType
        feeRateProvider = Core.shared.feeRateProviderFactory.provider(blockchainType: blockchainType)
    }

    private func validate() {
        guard let actualFeeRates, let satoshiPerByte else {
            return
        }

        if actualFeeRates.recommended > satoshiPerByte {
            if actualFeeRates.minimum <= satoshiPerByte {
                cautions = [.init(title: "send.fee_settings.stuck_warning.title".localized, text: "send.fee_settings.stuck_warning".localized, type: .warning)]
            } else {
                cautions = [.init(title: "send.fee_settings.fee_error.title".localized, text: "send.fee_settings.too_low".localized, type: .error)]
            }
        } else {
            cautions = []
        }
    }

    func sync() async throws {
        actualFeeRates = try await feeRateProvider?.feeRates()

        if usingRecommended, let actualFeeRates {
            satoshiPerByte = actualFeeRates.recommended
        }
    }

    func set(satoshiPerByte: Int) {
        self.satoshiPerByte = satoshiPerByte
        usingRecommended = (satoshiPerByte == actualFeeRates?.recommended)

        updateSubject.send()
    }

    func useRecommended() {
        satoshiPerByte = actualFeeRates?.recommended
        usingRecommended = true
        updateSubject.send()
    }
}
