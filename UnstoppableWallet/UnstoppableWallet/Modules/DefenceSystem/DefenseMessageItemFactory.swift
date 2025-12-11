import Foundation
import SwiftUI

enum DefenseSystemContentFactory {
    static func item(system: DefenseMessageModule.System, state: DefenseMessageModule.State, message: CustomStringConvertible?, action: DefenseMessageModule.ActionType? = nil) -> DefenseMessageItem {
        .init(image: state.image, title: title(system: system, state: state), text: message, action: action)
    }
    
    private static func title(system: DefenseMessageModule.System, state: DefenseMessageModule.State) -> CustomStringConvertible {
        "defense.\(system.rawValue).\(state.uid)".localized
    }

    @ViewBuilder static func view(item: DefenseMessageItem, state: DefenseMessageModule.State) -> some View {
        VStack(alignment: .leading, spacing: .margin12) {
            VStack(alignment: .leading, spacing: .margin8) {
                HStack(spacing: .margin8) {
                    if let image = item.image {
                        ThemeImage(image, size: .iconSize20, colorStyle: .custom(state.foregroundColor))
                    }
                    ThemeText(item.title, style: .headline2, colorStyle: .custom(state.foregroundColor))
                    Spacer()
                }
                
                if let text = item.text {
                    ThemeText(text, style: .subheadR, colorStyle: .custom(state.foregroundColor))
                }

                Spacer()
            }
            
            if let action = item.action {
                actionView(type: action, colorStyle: .custom(state.foregroundColor))
            }
        }
    }
    
    @ViewBuilder static func actionView(type: DefenseMessageModule.ActionType, colorStyle: ColorStyle) -> some View {
        switch type {
        case let .arrow(text):
            HStack(spacing: .margin8) {
                Spacer()
                ThemeText(text, style: .subheadSB, colorStyle: colorStyle)
                ThemeImage("arrow_m_right", size: .iconSize20, colorStyle: colorStyle)
            }
        }
    }
}

class DefenseMessageItem {
    let image: CustomStringConvertible?
    let title: CustomStringConvertible
    let text: CustomStringConvertible?
    let action: DefenseMessageModule.ActionType?
    
    init(image: CustomStringConvertible?, title: CustomStringConvertible, text: CustomStringConvertible?, action: DefenseMessageModule.ActionType? = nil) {
        self.image = image
        self.title = title
        self.text = text
        self.action = action
    }
}
