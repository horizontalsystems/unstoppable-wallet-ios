import SwiftUI
import ThemeKit

struct CheckboxStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }, label: {
            CheckBoxUiView(checked: configuration.$isOn)
        })

        configuration.label
    }
}
