import Combine
import UIKit

class PromoCodeBottomSheetViewModel: ObservableObject {
    private let purchaseManager = App.shared.purchaseManager
    
    private let initialPromo: String
    private let onApplyPromo: ((PurchaseManager.PromoData) -> ())
    private var currentTask: Task<Void, Never>?
    
    @Published var buttonState: ButtonState = .idle
    @Published var promocodeCautionState: CautionState = .none
    @Published var promocode: String {
        didSet {
            Task {
                if promocode == oldValue { return }
                await validatePromo()
            }
        }
    }
    
    var promoData: PurchaseManager.PromoData?
    
    init(promo: String, onApplyPromo: @escaping ((PurchaseManager.PromoData) -> ())) {
        self.initialPromo = promo
        self.onApplyPromo = onApplyPromo
        
        promocode = promo
    }
    
    @MainActor private func update(state: ButtonState, caution: CautionState) async {
        await MainActor.run { [weak self] in
            self?.buttonState = state
            self?.promocodeCautionState = caution
        }
    }
    
    private func validatePromo() async {
        currentTask?.cancel()
        currentTask = nil
        
        let promo = promocode.trimmingCharacters(in: .whitespacesAndNewlines)
        if promo == initialPromo {
            await update(state: .idle, caution: .none)
            return
        }
        
        currentTask = Task {
            do {
                await update(state: .loading, caution: .none)

                let data = try await purchaseManager.check(promocode: promo)
                await MainActor.run { [weak self] in
                    self?.promoData = data
                    self?.buttonState = .apply
                    self?.promocodeCautionState = .none
                }
            } catch {
                switch error {
                case PurchaseManager.PromoCodeError.invalid:
                    await update(state: .invalid, caution: .caution(Caution(text: "purchases.promocode.button.invalid".localized, type: .error)))
                case PurchaseManager.PromoCodeError.used:
                    await update(state: .alreadyUsed, caution: .caution(Caution(text: "purchases.promocode.button.already_used".localized, type: .error)))
                default:
                    if error is CancellationError { return }
                    await update(state: .invalid, caution: .caution(Caution(text: error.localizedDescription, type: .error)))
                }
            }
        }
    }
    
    func applyPromo() {
        if let promoData {
            onApplyPromo(promoData)
        }
    }
    
    deinit {
        currentTask?.cancel()
    }
    
}

extension PromoCodeBottomSheetViewModel {
    // Shortcut section
    var shortcuts: [ShortCutButtonType] {
        [.text("button.paste".localized)]
    }

    func onTap(index _: Int) {
        if let text = UIPasteboard.general.string?.replacingOccurrences(of: "\n", with: " ") {
            self.promocode = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
    
    func onTapDelete() {
        promocode = ""
    }
}

extension PromoCodeBottomSheetViewModel {
    enum ButtonState {
        case idle
        case loading
        case apply
        case invalid
        case alreadyUsed
    }
}
