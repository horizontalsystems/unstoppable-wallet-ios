import Combine
import SwiftUI

struct DebounceTextField: View {
    private let maxLineLimit = 4

    @State var publisher = PassthroughSubject<String, Never>()

    @State var label: String
    @Binding var value: String
    var valueChanged: ((_ value: String) -> Void)?

    @State var debounceSeconds = 2

    var body: some View {
        editView()
            .disableAutocorrection(true)
            .onChange(of: value) { value in
                publisher.send(value)
            }
            .onReceive(
                publisher.debounce(
                    for: .seconds(debounceSeconds),
                    scheduler: DispatchQueue.main
                )
            ) { value in
                if let valueChanged {
                    valueChanged(value)
                }
            }
    }

    @ViewBuilder func editView() -> some View {
        if #available(iOS 16.0, *) {
            TextField(label, text: $value, axis: .vertical)
                .lineLimit(1 ... maxLineLimit)
                .accentColor(.themeYellow)
        } else {
            TextField(label, text: $value)
                .accentColor(.themeYellow)
        }
    }
}
