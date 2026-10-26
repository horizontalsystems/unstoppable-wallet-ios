import SwiftUI

struct ReleaseNotesView: View {
    @StateObject private var viewModel: MarkdownViewModel
    @Environment(\.openURL) private var openURL

    private let isPresented: Binding<Bool>?

    init(url: URL, isPresented: Binding<Bool>? = nil) {
        _viewModel = StateObject(wrappedValue: MarkdownViewModel(url: url, mode: .gitRelease, handleRelativeUrl: false))
        self.isPresented = isPresented
    }

    var body: some View {
        content
            .closeNavigation(isPresented: isPresented)
    }

    private var content: some View {
        ThemeView {
            VStack(spacing: 0) {
                MarkdownContentView(viewModel: viewModel)
                    .frame(maxHeight: .infinity)

                followBar
            }
        }
        .navigationTitle("release_notes.title".localized)
    }

    private var followBar: some View {
        VStack(spacing: 0) {
            HorizontalDivider()

            HStack(spacing: .margin8) {
                socialButton(icon: "x_logo", urlString: "https://twitter.com/\(AppConfig.appTwitterAccount)")
                socialButton(icon: "telegram_logo", urlString: "https://t.me/\(AppConfig.appTelegramAccount)")

                Spacer()

                ThemeText("release_notes.follow_us".localized, style: .caption, colorStyle: .yellow)
                    .padding(.trailing, .margin24)
            }
            .padding(.leading, .margin8)
            .frame(height: 82)
        }
        .background(Color.themeTyler)
    }

    private func socialButton(icon: String, urlString: String) -> some View {
        // Plain Button: IconButton/ThemeButton force a fixed 56/32 pt (circular) frame, this needs a 52x82 tap area
        Button {
            if let url = URL(string: urlString) {
                openURL(url)
            }
        } label: {
            ThemeImage(icon, size: .iconSize24, colorStyle: .yellow)
                .frame(width: 52, height: 82)
                .contentShape(Rectangle())
        }
    }
}
