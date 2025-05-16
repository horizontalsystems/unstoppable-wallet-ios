import SwiftUI

struct InfoView: View {
    let items: [Item]
    @Binding var isPresented: Bool

    var body: some View {
        ThemeNavigationView {
            ScrollableThemeView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(items) { item in
                        switch item {
                        case let .header1(text):
                            Self.header1View(text: text)
                        case let .header3(text):
                            Self.header3View(text: text)
                        case let .text(text):
                            Self.textView(text: text)
                        case let .listItem(text):
                            Self.listItemView(text: text)
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
    }

    @ViewBuilder static func header1View(text: String) -> some View {
        VStack(alignment: .leading, spacing: .margin8) {
            Text(text)
                .foregroundColor(.themeLeah)
                .font(.themeTitle1)

            HorizontalDivider(color: .themeGray50)
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin12, trailing: .margin32))
    }

    @ViewBuilder static func header3View(text: String) -> some View {
        Text(text)
            .foregroundColor(.themeJacob)
            .font(.themeHeadline2)
            .padding(EdgeInsets(top: .margin16, leading: .margin32, bottom: .margin4, trailing: .margin32))
    }

    @ViewBuilder static func textView(text: String) -> some View {
        Text(text)
            .foregroundColor(.themeLeah)
            .font(.themeBody)
            .padding(EdgeInsets(top: .margin12, leading: .margin32, bottom: .margin12, trailing: .margin32))
    }

    @ViewBuilder static func listItemView(text: String) -> some View {
        HStack(alignment: .top, spacing: .margin16) {
            Text("•").textBody(color: .themeLeah)
            Text(text).themeBody(color: .themeLeah)
        }
        .padding(EdgeInsets(top: .margin12, leading: .margin24, bottom: .margin12, trailing: .margin24))
    }
}

extension InfoView {
    enum Item: Identifiable {
        case header1(text: String)
        case header3(text: String)
        case text(text: String)
        case listItem(text: String)

        var id: String {
            switch self {
            case let .header1(text): return text
            case let .header3(text): return text
            case let .text(text): return text
            case let .listItem(text): return text
            }
        }
    }
}
