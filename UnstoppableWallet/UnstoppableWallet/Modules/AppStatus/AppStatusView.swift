import SwiftUI

struct AppStatusView: View {
    let viewModel: AppStatusViewModel

    @State private var shareText: ShareText?

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                HStack(spacing: .margin8) {
                    Button(action: {
                        CopyHelper.copyAndNotify(value: viewModel.rawStatus)
                    }) {
                        Text("button.copy".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))

                    Button(action: {
                        shareText = ShareText(text: viewModel.rawStatus)
                    }) {
                        Text("button.share".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .gray))
                }
                .sheet(item: $shareText) { shareText in
                    ActivityView(text: shareText.text)
                        .ignoresSafeArea()
                }

                ForEach(viewModel.sections, id: \.title) { section in
                    VStack(spacing: 0) {
                        ListSectionHeader(text: section.title)

                        VStack(spacing: .margin12) {
                            ForEach(section.blocks, id: \.self) { fields in
                                ListSection {
                                    ForEach(fields, id: \.self) { field in
                                        ListRow {
                                            switch field {
                                            case let .info(title, value):
                                                Text(title).themeSubhead2()
                                                Text(value).themeSubhead1(color: .themeLeah, alignment: .trailing)
                                            case let .title(value):
                                                Text(value).themeSubhead1(color: .themeLeah)
                                            case let .raw(text):
                                                Text(text).themeCaption()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .navigationTitle("app_status.title".localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct ShareText: Identifiable {
        let id = UUID()
        let text: String
    }
}
