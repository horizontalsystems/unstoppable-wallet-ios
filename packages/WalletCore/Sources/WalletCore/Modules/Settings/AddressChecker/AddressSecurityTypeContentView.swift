import SwiftUI

struct AddressSecurityTypeContentView: View {
    private let securityManager = Core.shared.securityManager

    var body: some View {
        let types = AddressSecurityIssueType.allCases
        ForEach(types) { type in
            row(title: type.checkTitle, subtitle: type.checkSubtitle, isOn: binding(type))
        }
    }

    private func binding(_ type: AddressSecurityIssueType) -> Binding<Bool> {
        Binding(
            get: { securityManager.isCheckEnabled(type) },
            set: { securityManager.setCheckEnabled(type, enabled: $0) }
        )
    }

    private func row(title: CustomStringConvertible, subtitle: CustomStringConvertible, isOn: Binding<Bool>) -> some View {
        Cell(
            style: .secondary,
            middle: {
                MultiText(title: title, subtitle: subtitle)
            },
            right: {
                ThemeToggle(isOn: isOn)
            }
        )
    }
}
