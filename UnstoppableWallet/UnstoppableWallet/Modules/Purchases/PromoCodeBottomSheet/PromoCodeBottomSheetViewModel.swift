import Combine
import UIKit

class PromoCodeBottomSheetViewModel: ObservableObject {
    private let purchaseManager = App.shared.purchaseManager
    
    private let onApplyPromo: ((PurchaseManager.PromoData) -> ())
    private var currentTask: Task<Void, Never>?
    
    @Published var buttonState: ButtonState = .idle
    @Published var promocodeCautionState: CautionState = .none
    @Published var promocode: String = "" {
        didSet {
            validatePromo()
        }
    }
    
    var promoData: PurchaseManager.PromoData?

    init(onApplyPromo: @escaping ((PurchaseManager.PromoData) -> ())) {
        self.onApplyPromo = onApplyPromo
    }
    
    @MainActor private func update(state: ButtonState, caution: CautionState) async {
        await MainActor.run { [weak self] in
            self?.buttonState = state
            self?.promocodeCautionState = caution
        }
    }
    
    private func validatePromo() {
        if promocode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                await update(state: .idle, caution: .none)
            }
            return
        }

        buttonState = .loading
        Task {
            do {
                let promoData = try await purchaseManager.check(promocode: promocode)
                
                buttonState = .apply
            } catch {
                switch error {
                case PurchaseManager.PromoCodeError.invalid:
                    await update(state: .invalid, caution: .caution(Caution(text: "purchases.promocode.button.invalid".localized, type: .error)))
                case PurchaseManager.PromoCodeError.used:
                    await update(state: .alreadyUsed, caution: .caution(Caution(text: "purchases.promocode.button.already_used".localized, type: .error)))
                default:
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
