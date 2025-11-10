import SwiftUI

struct WalletConnectBottomSheetView: View {
    @StateObject var viewModel = WalletConnectBottomSheetViewModel()
    @Binding var isPresented: Bool

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                BSModule.view(for: .title(title: "HEllo Salam"))
                BSModule.view(for: .text(text: "This is always strange desctiprion text"))

                defenseSystem()
                    .animation(.easeInOut(duration: DefenseMessageModule.animationTime), value: viewModel.content)

                BSModule.view(for: .buttonGroup(.init(buttons: [
                    .init(style: .gray, title: "button.understood".localized) {
                        viewModel.changeContent()
                    },
                ])))
            }
        }
    }
    
    @ViewBuilder private func defenseSystem() -> some View {
        DefenseMessageView(direction: .bottom, state: viewModel.state, content: {
            Text(viewModel.content)
        })
    }
}
