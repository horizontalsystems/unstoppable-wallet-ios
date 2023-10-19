import SwiftUI

struct SimpleActivateView: View {
    @ObservedObject var viewModel: SimpleActivateViewModel

    let title: String
    let toggleText: String
    let description: String

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                VStack(spacing: 0) {
                    ListSection {
                        ListRow {
                            Toggle(isOn: $viewModel.activated) {
                                Text(toggleText).themeBody()
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .themeYellow))
                        }
                    }
                    ListSectionFooter(text: description)
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle(title)
    }
}
