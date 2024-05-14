import MarketKit
import SwiftUI

struct MarketNewsView: View {
    @ObservedObject var viewModel: MarketNewsViewModel

    var body: some View {
        ThemeView {
            switch viewModel.state {
            case .loading:
                loadingList()
            case let .loaded(posts):
                list(posts: posts)
            case .failed:
                SyncErrorView {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
        }
    }

    @ViewBuilder private func list(posts: [Post]) -> some View {
        ScrollView {
            LazyVStack(spacing: .margin12) {
                ForEach(posts.indices, id: \.self) { index in
                    let post = posts[index]

                    ListSection {
                        ClickableRow(
                            padding: EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: .margin16),
                            action: {
                                UrlManager.open(url: post.url)
                            }
                        ) {
                            itemContent(
                                source: post.source,
                                title: post.title,
                                body: post.body,
                                ago: timeAgo(interval: Date().timeIntervalSince1970 - post.timestamp)
                            )
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .refreshable {
            await viewModel.refresh()
        }
    }

    @ViewBuilder private func loadingList() -> some View {
        ScrollView {
            LazyVStack(spacing: .margin12) {
                ForEach(0 ... 5, id: \.self) { _ in
                    ListSection {
                        ListRow(padding: EdgeInsets(top: .margin16, leading: .margin16, bottom: .margin16, trailing: .margin16)) {
                            itemContent(
                                source: "Post Source",
                                title: "Post title post title post title post title post title post title",
                                body: "Post body post body post body post body post body post body post body post body post body post body post body post body post body post body post body post body",
                                ago: "1h ago"
                            )
                            .redacted()
                        }
                    }
                }
            }
            .padding(EdgeInsets(top: .margin12, leading: .margin16, bottom: .margin32, trailing: .margin16))
        }
        .simultaneousGesture(DragGesture(minimumDistance: 0), including: .all)
    }

    @ViewBuilder private func itemContent(source: String, title: String, body: String, ago: String) -> some View {
        VStack(alignment: .leading, spacing: .margin12) {
            VStack(alignment: .leading, spacing: .margin8) {
                Text(source).themeCaptionSB()

                VStack(alignment: .leading, spacing: .margin6) {
                    Text(title)
                        .themeHeadline2()
                        .lineLimit(3)

                    Text(body)
                        .themeSubhead2()
                        .lineLimit(2)
                }
            }

            Text(ago).themeMicro(color: .themeGray50)
        }
    }

    private func timeAgo(interval: TimeInterval) -> String {
        var interval = Int(interval) / 60

        // interval from post in minutes
        if interval < 60 {
            return "timestamp.min_ago".localized(max(1, interval))
        }

        // interval in hours
        interval /= 60
        if interval < 24 {
            return "timestamp.hours_ago".localized(interval)
        }

        // interval in days
        interval /= 24
        return "timestamp.days_ago".localized(interval)
    }
}
