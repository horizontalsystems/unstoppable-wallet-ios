import SwiftUI

struct AppStatusView: View {
    let viewModel: AppStatusViewModel

    var body: some View {
        ScrollableThemeView {
            VStack(spacing: .margin24) {
                HStack(spacing: .margin8) {
                    Button(action: {
                        stat(page: .appStatus, event: .copy(entity: .status))
                        CopyHelper.copyAndNotify(value: viewModel.rawStatus)
                    }) {
                        Text("button.copy".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .yellow))

                    Button(action: {
                        Coordinator.shared.present { _ in
                            ActivityView(activityItems: [viewModel.rawStatus])
                        }
                        stat(page: .appStatus, event: .share(entity: .status))
                    }) {
                        Text("button.share".localized)
                    }
                    .buttonStyle(PrimaryButtonStyle(style: .gray))
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
                                                Text(value)
                                                    .themeSubhead1(color: .themeLeah, alignment: .trailing)
                                                    .multilineTextAlignment(.trailing)
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
}
