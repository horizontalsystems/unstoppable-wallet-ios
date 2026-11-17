import SwiftUI

struct AddressSecurityTypeContentView: View {
    private let securityManager = Core.shared.securityManager

    var body: some View {
        let types = AddressSecurityIssueType.allCases

        VStack(spacing: 0) {
            ForEach(types) { type in
                row(title: type.checkTitle, subtitle: type.checkSubtitle, isOn: binding(type), identifier: identifier(type))

                if type != types.last {
                    HorizontalDivider()
                }
            }
        }
    }

    private func binding(_ type: AddressSecurityIssueType) -> Binding<Bool> {
        Binding(
            get: { securityManager.isCheckEnabled(type) },
            set: { securityManager.setCheckEnabled(type, enabled: $0) }
        )
    }

    private func identifier(_ type: AddressSecurityIssueType) -> String {
        switch type {
        case .phishing: return TestTags.secureSendPhishing
        case .blacklisted: return TestTags.secureSendBlacklist
        case .sanctioned: return TestTags.secureSendSanctions
        }
    }

    private func row(title: CustomStringConvertible, subtitle: CustomStringConvertible, isOn: Binding<Bool>, identifier: String) -> some View {
        Cell(
            style: .secondary,
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                ThemeToggle(isOn: isOn)
                    .accessibilityIdentifier(identifier)
            }
        )
    }
}
