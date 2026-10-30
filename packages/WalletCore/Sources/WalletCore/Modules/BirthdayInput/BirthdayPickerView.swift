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

                ThemeButton(text: "button.apply".localized) {
                    onSelect(selectedDate)
                    isPresented = false
                }
                .padding(EdgeInsets(top: .margin24, leading: .margin24, bottom: .margin16, trailing: .margin24))
            }
        }
    }
}
