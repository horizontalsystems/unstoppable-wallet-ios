import SwiftUI

struct MarkdownView: View {
    @StateObject private var viewModel: MarkdownViewModel

    private let isPresented: Binding<Bool>?

    init(url: URL, handleRelativeUrl: Bool = true, isPresented: Binding<Bool>? = nil) {
        _viewModel = StateObject(wrappedValue: MarkdownViewModel(url: url, mode: .article, handleRelativeUrl: handleRelativeUrl))
        self.isPresented = isPresented
    }

    var body: some View {
        ThemeView {
            MarkdownContentView(viewModel: viewModel)
        }
        .closeNavigation(isPresented: isPresented)
    }
}
