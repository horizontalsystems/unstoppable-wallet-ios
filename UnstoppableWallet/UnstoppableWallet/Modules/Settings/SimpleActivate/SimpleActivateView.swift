import SwiftUI

struct SimpleActivateView: View {
    @ObservedObject var viewModel: SimpleActivateViewModel

    let title: String
    let toggleText: String
    let description: String

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin32) {
                ListSection(footerText: description) {
                    ListRow {
                        Toggle(isOn: $viewModel.activated) {
                            Text(toggleText).themeBody()
                        }
                    }
                }
            }
                    .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
                .navigationBarTitle(title)
    }

}
