import SwiftUI

struct InfoNewView: View {
    let viewItems: [InfoModule.ViewItem]
    @Binding var isPresented: Bool

    var body: some View {
        ScrollableThemeView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewItems) { viewItem in
                    switch viewItem {
                    case let .header1(text):
                        header1View(text: text)
                    case let .header3(text):
                        header3View(text: text)
                    case let .text(text):
                        textView(text: text)
                    case .listItem:
                        EmptyView()
                    }
                }
            }
            .padding(.bottom, .margin32)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("button.close".localized) {
                    isPresented = false
                }
            }
        }
    }

    @ViewBuilder private func header1View(text: String) -> some View {
        VStack(alignment: .leading, spacing: .margin8) {
            Text(text)
                .foregroundColor(.themeLeah)
                .font(.themeTitle1)

            HorizontalDivider(color: .themeGray50)
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin12, trailing: .margin32))
    }

    @ViewBuilder private func header3View(text: String) -> some View {
        Text(text)
            .foregroundColor(.themeJacob)
            .font(.themeHeadline2)
            .padding(EdgeInsets(top: .margin16, leading: .margin32, bottom: .margin4, trailing: .margin32))
    }

    @ViewBuilder private func textView(text: String) -> some View {
        Text(text)
            .foregroundColor(.themeBran)
            .font(.themeBody)
            .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin12, trailing: .margin32))
    }
}
