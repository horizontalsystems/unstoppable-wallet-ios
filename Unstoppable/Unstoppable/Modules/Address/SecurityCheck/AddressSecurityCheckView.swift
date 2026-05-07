import SwiftUI

struct AddressSecurityCheckView: View {
    @ObservedObject var viewModel: AddressSecurityCheckViewModel
    let sourceStatPage: StatPage

    var body: some View {
        if !viewModel.issueTypes.isEmpty {
            switch viewModel.state {
            case .checking, .completed:
                SectionHeader(image: Image.defenseIcon, text: "purchases.secure_send".localized, horizontalInsets: .margin16)
                ListSection {
                    ForEach(viewModel.issueTypes) { type in
                        checkRow(type: type, state: viewModel.checkStates[type] ?? .notAvailable)
                    }
                }
                .themeListStyle(.bordered)

                let cautions = viewModel.issueTypes.filter { viewModel.checkStates[$0] == .detected }.map(\.caution)

                if !cautions.isEmpty {
                    VStack(spacing: .margin16) {
                        ForEach(cautions.indices, id: \.self) { index in
                            AlertCardView(caution: cautions[index])
                        }
                    }
                    .padding(.top, .margin16)
                }
            default:
                EmptyView()
            }
        }
    }

    @ViewBuilder private func checkRow(type: AddressSecurityIssueType, state: AddressSecurityCheckViewModel.CheckState) -> some View {
        Cell(
            middle: {
                MultiText(subtitle: type.checkTitle)
            },
            right: {
                switch state {
                case .checking:
                    ProgressView()
                case .clear:
                    RightTextIcon(text: ComponentText(text: "send.address.check.clear".localized, colorStyle: .green))
                case .detected:
                    RightTextIcon(text: ComponentText(text: "send.address.check.detected".localized, colorStyle: .red))
                case .notAvailable:
                    RightTextIcon(text: ComponentText(text: "n/a".localized, colorStyle: .primary))
                case .locked:
                    Image.lockIcon
                case .disabled:
                    RightTextIcon(text: ComponentText(text: "send.address.check.disabled".localized, colorStyle: .primary))
                }
            }
        )
        .tapIntercept(active: true) {
            switch state {
            case .locked:
                Coordinator.shared.presentPurchase(premiumFeature: .secureSend, page: sourceStatPage, trigger: .addressChecker)
            default:
                Coordinator.shared.present(type: .bottomSheet) { isPresented in
                    SecureSendBottomSheetView(isPresented: isPresented)
                }
            }
        }
    }
}
