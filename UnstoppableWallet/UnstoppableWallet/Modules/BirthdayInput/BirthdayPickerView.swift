import SwiftUI

struct BirthdayPickerView: View {
    private let startDate: Date
    private let onSelect: (Date) -> Void
    @Binding var isPresented: Bool

    @State private var selectedDate: Date

    init(date: Date, startDate: Date, isPresented: Binding<Bool>, onSelect: @escaping (Date) -> Void) {
        selectedDate = date
        self.startDate = startDate
        self.onSelect = onSelect
        _isPresented = isPresented
    }

    var body: some View {
        ThemeView(style: .list) {
            VStack(spacing: 0) {
                BSTitleView(showGrabber: true, title: "birthday_input.picker.select_date".localized, isPresented: $isPresented)

                ThemeText("birthday_input.picker.description".localized, style: .subhead)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .padding(.bottom, 16)

                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: startDate ... Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale.current)
                .accentColor(.themeLeah)

                Button(
                    action: {
                        onSelect(selectedDate)
                        isPresented = false
                    },
                    label: {
                        Text("button.apply".localized)
                    }
                )
                .buttonStyle(PrimaryButtonStyle(style: .yellow))
                .padding(EdgeInsets(top: 24, leading: 24, bottom: 16, trailing: 24))
            }
        }
    }
}
