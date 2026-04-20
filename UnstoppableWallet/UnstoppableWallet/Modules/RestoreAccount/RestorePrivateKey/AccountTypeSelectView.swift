import MarketKit
import SwiftUI

struct AccountTypeSelectView: View {
    let accountName: String
    let accountTypes: [AccountType]
    @Binding var isParentPresented: Bool

    @State private var selectCoinsAccountType: AccountType?

    private var items: [ViewItem] {
        accountTypes.compactMap { Self.viewItem(accountType: $0) }
    }

    private static func viewItem(accountType: AccountType) -> ViewItem? {
        switch accountType {
        case .evmPrivateKey:
            return ViewItem(title: "restore.select_key_type.evm".localized, description: "restore.select_key_type.evm.description".localized, accountType: accountType)
        case .trcPrivateKey:
            return ViewItem(title: "restore.select_key_type.trc".localized, description: "restore.select_key_type.trc.description".localized, accountType: accountType)
        default: return nil
        }
    }

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: 0) {
                ListSection {
                    ForEach(items, id: \.title) { item in
                        ClickableRow(action: {
                            onTap(item: item)
                        }) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title).themeBody()
                                Text(item.description).themeSubhead2()
                            }
                            Spacer()
                            Image.disclosureIcon
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("restore.select_key_type".localized)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: Binding(
            get: { selectCoinsAccountType != nil },
            set: { if !$0 { selectCoinsAccountType = nil } }
        )) {
            if let accountType = selectCoinsAccountType {
                RestoreCoinsView(accountName: accountName, accountType: accountType, isParentPresented: $isParentPresented)
            }
        }
    }

    private func onTap(item: ViewItem) {
        switch item.accountType {
        case .evmPrivateKey:
            selectCoinsAccountType = item.accountType
        case .trcPrivateKey:
            restoreDirectly(accountType: item.accountType)
        default: break
        }
    }

    private func restoreDirectly(accountType: AccountType) {
        let supportedTokens = RestoreHelper.supportedTokens(accountType: accountType)
        if let token = supportedTokens.first {
            RestoreHelper.restoreSingleBlockchain(accountName: accountName, accountType: accountType, token: token)
        }
        HudHelper.instance.show(banner: .imported)
        isParentPresented = false
    }
}

extension AccountTypeSelectView {
    struct ViewItem {
        let title: String
        let description: String
        let accountType: AccountType
    }
}
