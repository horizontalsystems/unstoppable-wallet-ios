import SwiftUI

struct MarkdownContentView: View {
    @ObservedObject var viewModel: MarkdownViewModel

    @State private var pushedUrl: URL?

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case let .loaded(viewItems):
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewItems.indexedElements) { item in
                            MarkdownBlockView(viewItem: item.element)
                        }

                        brandFooter
                    }
                }
            case .failed:
                SyncErrorView {
                    viewModel.onRetry()
                }
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            switch viewModel.linkAction(url: url) {
            case let .pushMarkdown(resolvedUrl):
                pushedUrl = resolvedUrl
                return .handled
            case let .external(externalUrl):
                guard externalUrl.scheme == "http" || externalUrl.scheme == "https" else {
                    return .systemAction
                }

                Coordinator.shared.present(url: externalUrl)
                return .handled
            }
        })
        .navigationDestination(item: $pushedUrl) { url in
            MarkdownView(url: url)
        }
    }

    private var brandFooter: some View {
        VStack(spacing: 0) {
            HorizontalDivider()

            ThemeText("© \(AppConfig.companyName)", style: .caption)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: .margin12, leading: .margin24, bottom: .margin32, trailing: .margin24))
        }
        .padding(.top, .margin32)
    }
}
