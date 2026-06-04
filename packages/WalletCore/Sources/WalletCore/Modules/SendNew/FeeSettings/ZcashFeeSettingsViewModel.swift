// import SwiftUI
// import ZcashLightClientKit
//
// @MainActor
// class ZcashFeeSettingsViewModel: ObservableObject {
//    private static let resolveFeeDebounceMilliseconds = 300
//    private static let marginalFeeStep = ZcashAdapter.defaultZip317MarginalFee.amount / 10
//
//    private let service: ZcashTransactionService
//    private var resolveFeeTask: Task<Void, Never>?
//    private var feeZip317MarginalFee: Zatoshi?
//
//    @Published var marginalFeeCautionState: FieldCautionState = .none
//    @Published var applyEnabled = false
//    @Published var resetEnabled = false
//    @Published var cautions = [CautionNew]()
//
//    @Published var fee: Decimal?
//    @Published var zip317MarginalFee: Zatoshi? {
//        didSet {
//            sync()
//        }
//    }
//
//    @Published private var _marginalFeeValue = ""
//    var marginalFeeValue: Binding<String> {
//        Binding(
//            get: { self._marginalFeeValue },
//            set: { newValue in
//                self._marginalFeeValue = newValue
//                self.handleChange()
//            }
//        )
//    }
//
//    init(service: ZcashTransactionService, fee: Decimal?) {
//        self.service = service
//        self.fee = fee
//        feeZip317MarginalFee = service.currentZip317MarginalFee
//        zip317MarginalFee = service.currentZip317MarginalFee
//        _marginalFeeValue = service.currentZip317MarginalFee.amount.description
//        sync()
//    }
//
//    deinit {
//        resolveFeeTask?.cancel()
//    }
//
//    private func sync() {
//        guard let zip317MarginalFee else {
//            resolveFeeTask?.cancel()
//            applyEnabled = false
//            resetEnabled = true
//            return
//        }
//
//        cautions = ZcashTransactionService.validate(
//            zip317MarginalFee: zip317MarginalFee
//        )
//
//        applyEnabled = service.currentZip317MarginalFee != zip317MarginalFee && !cautions.contains(where: { $0.type == .error })
//        resetEnabled = zip317MarginalFee != service.recommendedZip317MarginalFee
//
//        marginalFeeCautionState = ZcashAdapter.zip317MarginalFeeRange.contains(zip317MarginalFee.amount) ? .none : .caution(.error)
//
//        syncFee(zip317MarginalFee: zip317MarginalFee)
//    }
//
//    private func syncFee(zip317MarginalFee: Zatoshi) {
//        guard !cautions.contains(where: { $0.type == .error }) else {
//            resolveFeeTask?.cancel()
//            return
//        }
//
//        guard feeZip317MarginalFee != zip317MarginalFee else {
//            return
//        }
//
//        resolveFeeTask?.cancel()
//
//        resolveFeeTask = Task { [weak self, service] in
//            do {
//                try await Task.sleep(for: .milliseconds(Self.resolveFeeDebounceMilliseconds))
//            } catch {
//                return
//            }
//
//            let fee = try? await service.resolveFee(zip317MarginalFee: zip317MarginalFee)
//
//            guard !Task.isCancelled else {
//                return
//            }
//
//            self?.fee = fee
//            self?.feeZip317MarginalFee = zip317MarginalFee
//        }
//    }
//
//    private func handleChange() {
//        guard let marginalFee = Int64(_marginalFeeValue) else {
//            resolveFeeTask?.cancel()
//            marginalFeeCautionState = .caution(.error)
//            applyEnabled = false
//            return
//        }
//
//        zip317MarginalFee = Zatoshi(marginalFee)
//    }
//
//    private func updateByStep(value: Int64, range: ClosedRange<Int64>, step: Int64, direction: StepChangeButtonsViewDirection) -> Int64 {
//        switch direction {
//        case .down: return max(value - step, range.lowerBound)
//        case .up: return min(value + step, range.upperBound)
//        }
//    }
// }
//
// extension ZcashFeeSettingsViewModel {
//    func stepChangeMarginalFee(_ direction: StepChangeButtonsViewDirection) {
//        guard let zip317MarginalFee else {
//            return
//        }
//
//        marginalFeeValue.wrappedValue = updateByStep(
//            value: zip317MarginalFee.amount,
//            range: ZcashAdapter.zip317MarginalFeeRange,
//            step: Self.marginalFeeStep,
//            direction: direction
//        ).description
//    }
//
//    func onReset() {
//        _marginalFeeValue = service.recommendedZip317MarginalFee.amount.description
//        handleChange()
//    }
//
//    func apply() {
//        guard let zip317MarginalFee else {
//            return
//        }
//
//        service.set(
//            zip317MarginalFee: zip317MarginalFee == service.recommendedZip317MarginalFee ? nil : zip317MarginalFee
//        )
//    }
// }
