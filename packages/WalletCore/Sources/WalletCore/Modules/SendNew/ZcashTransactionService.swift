// import Combine
// import Foundation
// import MarketKit
// import ZcashLightClientKit
//
// class ZcashTransactionService {
//    enum ProposalRequest {
//        case transfer(amount: Decimal, recipient: Recipient, memo: String?)
//        case shield(amount: Decimal, recipient: Recipient?, memo: String?)
//    }
//
//    private let token: Token
//    private let proposalRequest: ProposalRequest
//    private let updateSubject = PassthroughSubject<Void, Never>()
//
//    private var zip317MarginalFee: Zatoshi? {
//        didSet {
//            validate()
//        }
//    }
//
//    private(set) var cautions = [CautionNew]()
//
//    init(token: Token, proposalRequest: ProposalRequest, initialTransactionSettings: InitialTransactionSettings? = nil) {
//        self.token = token
//        self.proposalRequest = proposalRequest
//
//        if case let .some(.zcash(zip317MarginalFee)) = initialTransactionSettings {
//            self.zip317MarginalFee = zip317MarginalFee
//        }
//
//        validate()
//    }
//
//    private func validate() {
//        cautions = Self.validate(
//            zip317MarginalFee: currentZip317MarginalFee
//        )
//    }
// }
//
// extension ZcashTransactionService: ITransactionService {
//    var transactionSettings: TransactionSettings? {
//        .zcash(
//            zip317MarginalFee: currentZip317MarginalFee
//        )
//    }
//
//    var modified: Bool {
//        zip317MarginalFee != nil
//    }
//
//    var updatePublisher: AnyPublisher<Void, Never> {
//        updateSubject.eraseToAnyPublisher()
//    }
//
//    func sync() async throws {}
// }
//
// extension ZcashTransactionService {
//    var recommendedZip317MarginalFee: Zatoshi {
//        ZcashAdapter.defaultZip317MarginalFee
//    }
//
//    var currentZip317MarginalFee: Zatoshi {
//        zip317MarginalFee ?? recommendedZip317MarginalFee
//    }
//
//    func set(zip317MarginalFee: Zatoshi?) {
//        self.zip317MarginalFee = zip317MarginalFee
//        updateSubject.send()
//    }
//
//    func resolveFee(zip317MarginalFee: Zatoshi) async throws -> Decimal {
//        guard let adapter = Core.shared.adapterManager.adapter(for: token) as? ZcashAdapter else {
//            throw AppError.unknownError
//        }
//
//        let proposal: Proposal?
//
//        switch proposalRequest {
//        case let .transfer(amount, recipient, memo):
//            proposal = try await adapter.sendProposal(
//                amount: amount,
//                address: recipient,
//                memo: memo.flatMap { try? Memo(string: $0) },
//                zip317MarginalFee: zip317MarginalFee
//            )
//        case let .shield(_, recipient, memo):
//            proposal = try await adapter.shieldProposal(
//                threshold: ZcashAdapter.minimalThreshold,
//                address: recipient,
//                memo: memo.flatMap { try? Memo(string: $0) },
//                zip317MarginalFee: zip317MarginalFee
//            )
//        }
//
//        guard let proposal else {
//            throw AppError.unknownError
//        }
//
//        return proposal.totalFeeRequired().decimalValue.decimalValue
//    }
// }
//
// extension ZcashTransactionService {
//    static func validate(zip317MarginalFee: Zatoshi) -> [CautionNew] {
//        var cautions = [CautionNew]()
//
//        if zip317MarginalFee.amount < ZcashAdapter.zip317MarginalFeeRange.lowerBound {
//            cautions.append(.init(
//                title: "fee_settings.errors.invalid_value".localized,
//                text: "fee_settings.errors.zcash_marginal_fee_too_low".localized,
//                type: .error
//            ))
//        } else if zip317MarginalFee.amount > ZcashAdapter.zip317MarginalFeeRange.upperBound {
//            cautions.append(.init(
//                title: "fee_settings.errors.invalid_value".localized,
//                text: "fee_settings.errors.zcash_marginal_fee_too_high".localized,
//                type: .error
//            ))
//        }
//
//        return cautions
//    }
// }
