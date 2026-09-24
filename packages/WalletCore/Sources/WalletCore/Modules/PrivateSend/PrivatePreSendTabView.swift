import SwiftUI

struct PrivatePreSendTabView: View {
    @ObservedObject var viewModel: PrivatePreSendViewModel
    let addressVisible: Bool

    @Binding var path: NavigationPath
    @Binding var isPresented: Bool

    var body: some View {
        PreSendFormView(viewModel: viewModel, addressVisible: addressVisible, path: $path, isPresented: $isPresented) { _ in
            AlertCardView(.init(icon: "info_filled", title: "private_send.tab.caution.title".localized, text: "private_send.tab.caution.text".localized, type: .regular))
                .padding(.top, 16)
                .padding(.horizontal, 16)
        }
    }
}
