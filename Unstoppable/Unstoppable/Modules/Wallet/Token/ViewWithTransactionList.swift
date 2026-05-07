import SwiftUI

struct ViewWithTransactionList<Content: View, TransactionList: View>: View {
    let transactionListStatus: TransactionListStatus
    let content: () -> Content
    let transactionList: () -> TransactionList

    var body: some View {
        switch transactionListStatus {
        case .show:
            ThemeList(bottomSpacing: .margin16) {
                content().themeListTopView()
                transactionList()
            }
            .themeListScrollHeader()
        default:
            VStack(spacing: 0) {
                content()

                placeholderView(transactionListStatus: transactionListStatus)
            }
        }
    }

    @ViewBuilder private func placeholderView(transactionListStatus: TransactionListStatus) -> some View {
        if let icon = transactionListStatus.icon {
            PlaceholderViewNew(
                icon: icon,
                title: transactionListStatus.title,
                subtitle: transactionListStatus.subtitle
            )
        }
    }
}
