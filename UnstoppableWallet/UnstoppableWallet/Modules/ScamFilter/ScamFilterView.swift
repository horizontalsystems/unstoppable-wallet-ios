import SwiftUI

struct ScamFilterView: View {
    @ObservedObject var viewModel: ScamFilterViewModel

    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                VStack(spacing: 0) {
                    ListSection {
                        ListRow {
                            Toggle(isOn: $viewModel.enabled) {
                                Text("scam_filter.enabled".localized).themeBody()
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                        }
                    }
                    ListSectionFooter(text: "scam_filter.description".localized)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("scam_filter.title".localized)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("button.done".localized) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
