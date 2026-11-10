import SwiftUI
import UIKit

@MainActor
struct ThemeInputButton: Identifiable {
    enum Kind {
        case icon(String)
        case text(String)
    }

    let id: String
    let kind: Kind
    let identifier: String?
    let action: @MainActor () -> Void

    private init(id: String, kind: Kind, identifier: String?, action: @escaping @MainActor () -> Void) {
        self.id = id
        self.kind = kind
        self.identifier = identifier
        self.action = action
    }

    static func icon(_ name: String, identifier: String? = nil, action: @escaping @MainActor () -> Void) -> ThemeInputButton {
        ThemeInputButton(id: name, kind: .icon(name), identifier: identifier, action: action)
    }

    static func text(_ text: String, identifier: String? = nil, action: @escaping @MainActor () -> Void) -> ThemeInputButton {
        ThemeInputButton(id: text, kind: .text(text), identifier: identifier, action: action)
    }

    static func paste(identifier: String? = nil, onPaste: @escaping @MainActor (String) -> Void) -> ThemeInputButton {
        .text("button.paste".localized, identifier: identifier) {
            if let string = UIPasteboard.general.string {
                onPaste(string)
            }
        }
    }

    static func scan(options: ScanQrModule.Options = [.paste, .picker], identifier: String? = nil, onScan: @escaping @MainActor (String) -> Void) -> ThemeInputButton {
        .icon("scan", identifier: identifier) {
            Coordinator.shared.present { isPresented in
                ScanQrView(options: options, isPresented: isPresented) { text in
                    onScan(text)
                }
                .ignoresSafeArea()
            }
        }
    }

    static func delete(identifier: String? = nil, action: @escaping @MainActor () -> Void) -> ThemeInputButton {
        .icon("trash", identifier: identifier, action: action)
    }

    /// The id does not follow the eye_on / eye_off icon, so toggling keeps the button's identity
    static func secureToggle(_ secured: Binding<Bool>, identifier: String? = nil) -> ThemeInputButton {
        let icon = secured.wrappedValue ? "eye_off" : "eye_on"

        return ThemeInputButton(id: "secure_toggle", kind: .icon(icon), identifier: identifier) {
            secured.wrappedValue.toggle()
        }
    }

    static func shortcuts(isEmpty: Bool, whenEmpty: [ThemeInputButton], deleteIdentifier: String? = nil, onDelete: @escaping @MainActor () -> Void) -> [ThemeInputButton] {
        isEmpty ? whenEmpty : [.delete(identifier: deleteIdentifier, action: onDelete)]
    }

    static func steps(minusIdentifier: String? = nil, plusIdentifier: String? = nil, onTap: @escaping @MainActor (StepChangeButtonsViewDirection) -> Void) -> [ThemeInputButton] {
        [
            .icon("minus", identifier: minusIdentifier) { onTap(.down) },
            .icon("plus", identifier: plusIdentifier) { onTap(.up) },
        ]
    }
}
