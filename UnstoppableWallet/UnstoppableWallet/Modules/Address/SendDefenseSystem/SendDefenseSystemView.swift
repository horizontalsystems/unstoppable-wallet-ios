import MarketKit
import SwiftUI

struct SendDefenseSystemView: View {
    @ObservedObject var viewModel: SendDefenseSystemViewModel

    var body: some View {
        let (state, message, action) = state
        DefenseMessageView(
            direction: .bottom,
            state: state,
            content: {
                let item = DefenseSystemContentFactory.item(system: .send, state: state, message: message, action: action?.type)
                DefenseSystemContentFactory.view(item: item, state: state)
            },
            action: action?.action
        )
    }
    
    private var state: (DefenseMessageModule.State, CustomStringConvertible, Action?) {
        var state = DefenseMessageModule.State.positive
        var message = "defense.send.positive.message_1".localized
        var action: Action?

        if !viewModel.premiumEnabled {
            state =  .attention
            message = "defense.send.attention.message_1".localized
            action = .init(
                type: .arrow("defense.non_private.activate".localized),
                action: {
                    Coordinator.shared.presentPurchase(premiumFeature: .scamProtection, page: .send, trigger: .addressChecker)
                }
            )
        } else if viewModel.isChecking {
            state = .loading
            message = ""
        } else if !viewModel.detectedIssueTypes.isEmpty {
            state = .negative
            message = "defense.send.negative.message_1".localized(viewModel.detectedIssueTypes.map { $0.checkTitle }.joined(separator: " / "))
        }
            
        return (state, message, action)
    }
}

extension SendDefenseSystemView {
    struct Action {
        let type: DefenseMessageModule.ActionType
        let action : () -> Void
    }
}

private struct CheckRowView: View {
    let type: AddressSecurityIssueType
    let state: SendDefenseSystemViewModel.State
    let destination: AddressViewModel.Destination

    var body: some View {
        HStack(spacing: .margin8) {
            HStack(spacing: .margin8) {
                Image("star_premium_20").themeIcon(color: .themeJacob)
                Text(type.checkTitle).textSubhead2()
            }

            Spacer()

            stateView
        }
        .padding(.horizontal, .margin16)
        .frame(minHeight: 40)
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap()
        }
    }

    @ViewBuilder
    private var stateView: some View {
        switch state {
        case .idle:
            EmptyView()
        case .checking:
            ProgressView()
        case .clear:
            Text("send.address.check.clear".localized)
                .textSubhead2(color: .themeRemus)
        case .detected:
            Text("send.address.check.detected".localized)
                .textSubhead2(color: .themeLucian)
        case .notAvailable:
            Text("n/a".localized)
                .textSubhead2()
        case .locked:
            Image("lock_20").themeIcon()
        case .disabled:
            Text("send.address.check.disabled".localized)
                .textSubhead2(color: .themeLeah)
        }
    }

    private func handleTap() {
        switch state {
        case .locked:
            Coordinator.shared.presentPurchase(
                premiumFeature: .scamProtection,
                page: destination.sourceStatPage,
                trigger: .addressChecker
            )
        default:
            Coordinator.shared.present(info: type.description)
        }
    }
}
