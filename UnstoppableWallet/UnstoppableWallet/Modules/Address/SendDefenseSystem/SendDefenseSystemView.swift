import MarketKit
import SwiftUI

struct SendDefenseSystemView: View {
    @ObservedObject var viewModel: SendDefenseSystemViewModel

    var body: some View {
        VStack(spacing: 0) {
            ListSection {
                VStack(spacing: 0) {
                    ForEach(AddressSecurityIssueType.allCases.filter { type in
                        // Показываем только те типы, которые есть в viewModel
                        viewModel.checkStates.keys.contains(type)
                    }) { type in
                        CheckRowView(
                            type: type,
                            state: viewModel.checkStates[type] ?? .idle,
                            destination: viewModel.destination
                        )
                    }
                }
            }
            .themeListStyle(.bordered)

            if !viewModel.detectedIssueTypes.isEmpty {
                VStack(spacing: .margin16) {
                    ForEach(viewModel.detectedIssueTypes) { type in
                        HighlightedTextView(caution: type.caution)
                    }
                }
                .padding(.top, .margin16)
            }
        }
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
