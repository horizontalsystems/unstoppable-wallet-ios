import Combine
import UIKit

class PromoCodeBottomSheetViewModel: ObservableObject {
    private let onSubscribe: (() -> ())

    @Published var promocodeCautionState: CautionState = .none
    @Published var promocode: String = "" {
        didSet {
            validatePromo()
        }
    }

    init(onSubscribe: @escaping (() -> ())) {
        self.onSubscribe = onSubscribe
    }
    
    private func validatePromo() {
        
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
