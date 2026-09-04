import SwiftUI

// Maps the module's defense state onto the shared Defense System bubble
struct WCNDefenseBlock: View {
    let state: WCNDefenseState
    let onActivate: () -> Void

    var body: some View {
        switch state {
        case .disabled:
            DefenseSystemView(placement: .bottom, style: .attention, icon: "warning_filled", title: "wallet_connect.defense.attention.title".localized, text: "wallet_connect.defense.attention.text".localized, action: ("wallet_connect.defense.activate".localized, onActivate))
        case .loading:
            DefenseSystemView(placement: .bottom, style: .loading, text: "wallet_connect.defense.loading".localized)
        case .notAvailable:
            DefenseSystemView(placement: .bottom, style: .notAvailable, text: "wallet_connect.defense.not_available".localized)
        case .safe:
            DefenseSystemView(placement: .bottom, style: .positive, icon: "defense_filled", title: "wallet_connect.defense.safe.title".localized, text: "wallet_connect.defense.safe.text".localized)
        case .danger:
            DefenseSystemView(placement: .bottom, style: .negative, icon: "warning_filled", title: "wallet_connect.defense.danger.title".localized, text: "wallet_connect.defense.danger.text".localized)
        case .scam:
            DefenseSystemView(placement: .bottom, style: .negative, icon: "warning_filled", title: "wallet_connect.defense.scam.title".localized, text: "wallet_connect.defense.scam.text".localized)
        }
    }
}
