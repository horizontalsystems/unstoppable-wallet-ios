import MarketKit
import SwiftUI

struct ContactBookBlockchainSelectView: View {
    private let blockchains: [Blockchain]
    private let selected: Blockchain
    private let onSelect: (Blockchain) -> Void

    @Binding private var isPresented: Bool

    init(blockchains: [Blockchain], selected: Blockchain, isPresented: Binding<Bool>, onSelect: @escaping (Blockchain) -> Void) {
        self.blockchains = blockchains
        self.selected = selected
        self.onSelect = onSelect
        _isPresented = isPresented
    }

    var body: some View {
        ThemeNavigationStack {
            ScrollableThemeView {
                ListSection {
                    ForEach(blockchains, id: \.uid) { blockchain in
                        ClickableRow(action: {
                            onSelect(blockchain)
                            isPresented = false
                        }) {
                            BlockchainIcon(blockchain: blockchain)

                            Text(blockchain.name).themeBody()

                            if blockchain == selected {
                                Image.checkIcon
                            }
                        }
                    }
                }
                .themeListStyle(.transparent)
                .padding(.bottom, .margin32)
            }
            .navigationTitle("contacts.contact.address.blockchains".localized)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        isPresented = false
                    }) {
                        Image("close")
                    }
                }
            }
        }
    }
}
