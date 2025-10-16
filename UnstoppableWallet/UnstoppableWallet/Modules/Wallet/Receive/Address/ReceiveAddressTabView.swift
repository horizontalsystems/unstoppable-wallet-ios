import MarketKit
import SwiftUI

struct ReceiveAddressTabView: View {
    @StateObject private var viewModelFactory: ReceiveAddressViewModelFactory
    var onDismiss: (() -> Void)?

    @State private var currentTab: DepositAddressType = .legacy
    private let tabs: [DepositAddressType]

    @Environment(\.presentationMode) private var presentationMode

    init(wallet: Wallet, tabs: [DepositAddressType], currentTab: DepositAddressType, onDismiss: (() -> Void)? = nil) {
        self.tabs = tabs
        self.currentTab = currentTab
        self.onDismiss = onDismiss

        _viewModelFactory = StateObject(wrappedValue: ReceiveAddressViewModelFactory(wallet: wallet))
    }

    var body: some View {
        ScrollableThemeView {
            if tabs.count > 1 {
                TabHeaderView(
                    tabs: tabs.map(\.name),
                    currentTabIndex: Binding(
                        get: {
                            tabs.firstIndex(of: currentTab) ?? 0
                        },
                        set: { index in
                            currentTab = tabs[index]
                        }
                    )
                )
            }

            ReceiveAddressView(factory: viewModelFactory, type: currentTab)
                .id(currentTab)
                .frame(maxHeight: .infinity)
        }
        .navigationTitle(viewModelFactory.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("button.cancel".localized) {
                    if let onDismiss {
                        onDismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .accentColor(.themeGray)
    }
}

extension ReceiveAddressTabView {
    static func instance(wallet: Wallet, onDismiss: (() -> Void)? = nil) -> Self {
        guard let adapter = Core.instance?.adapterManager.adapter(for: wallet) as? IDepositAdapter else {
            return .init(wallet: wallet, tabs: [.legacy], currentTab: .legacy, onDismiss: onDismiss)
        }

        return .init(wallet: wallet, tabs: adapter.addressTypes, currentTab: adapter.addressTypes.first ?? .legacy, onDismiss: onDismiss)
    }
}
