import SwiftUI

struct DoubleSpendInfoView: View {
    private let transactionHash: String
    private let conflictingTransactionHash: String
    @Binding private var isPresented: Bool

    init(transactionHash: String, conflictingTransactionHash: String, isPresented: Binding<Bool>) {
        self.transactionHash = transactionHash
        self.conflictingTransactionHash = conflictingTransactionHash
        _isPresented = isPresented
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin16) {
                AlertCardView(AlertCardViewItem(text: "double_spend_info.header".localized, type: .caution, style: .structured))

                ListSection {
                    VStack(spacing: 0) {
                        HexField(title: "double_spend_info.this_hash".localized, value: transactionHash).listRow()
                        HexField(title: "double_spend_info.conflicting_hash".localized, value: conflictingTransactionHash).listRow()
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("double_spend_info.title".localized)
        .closeNavigation(isPresented: $isPresented)
    }
}
