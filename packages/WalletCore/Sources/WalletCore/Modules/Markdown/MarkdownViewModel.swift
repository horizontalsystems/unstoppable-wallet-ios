import Combine
import Down
import Foundation
import HsExtensions
import HsToolKit

@MainActor
final class MarkdownViewModel: ObservableObject {
    private let url: URL
    private let mode: Mode
    private let handleRelativeUrl: Bool
    private let networkManager: NetworkManager
    private var tasks = Set<AnyTask>()

    @Published private(set) var state: State = .loading

    init(url: URL, mode: Mode, handleRelativeUrl: Bool, networkManager: NetworkManager = Core.shared.networkManager) {
        self.url = url
        self.mode = mode
        self.handleRelativeUrl = handleRelativeUrl
        self.networkManager = networkManager

        sync()
    }

    private var markdownUrl: URL? {
        Self.markdownUrl(url: url, mode: mode)
    }

    private func sync() {
        tasks = Set()

        state = .loading

        Task { [weak self, url, mode, networkManager] in
            do {
                let viewItems = try await Self.loadViewItems(url: url, mode: mode, networkManager: networkManager)

                guard !Task.isCancelled else {
                    return
                }

                self?.state = .loaded(viewItems: viewItems)
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                self?.state = .failed(error: error)
            }
        }
        .store(in: &tasks)
    }

    private nonisolated static func markdownUrl(url: URL, mode: Mode) -> URL? {
        switch mode {
        case .article: return url
        case .gitRelease: return nil
        }
    }

    // Runs off the main actor: network fetch, Down parsing and attributed string building
    private nonisolated static func loadViewItems(url: URL, mode: Mode, networkManager: NetworkManager) async throws -> [MarkdownBlockViewItem] {
        let content: String

        switch mode {
        case .article:
            let data = try await networkManager.fetchData(url: url)
            content = String(decoding: data, as: UTF8.self)
        case .gitRelease:
            let release: GitHubRelease = try await networkManager.fetch(url: url)
            content = release.body
        }

        try Task.checkCancellation()

        return MarkdownParser.viewItems(content: content, url: markdownUrl(url: url, mode: mode), configuration: mode.config)
    }
}

extension MarkdownViewModel {
    func onRetry() {
        sync()
    }

    func linkAction(url: URL) -> LinkAction {
        guard handleRelativeUrl, url.pathExtension == "md" else {
            return .external(url: url)
        }

        let resolvedUrl = URL(string: url.absoluteString, relativeTo: markdownUrl)?.absoluteURL

        return .pushMarkdown(url: resolvedUrl ?? url)
    }
}

extension MarkdownViewModel {
    enum Mode {
        case article
        case gitRelease

        var config: DownStylerConfiguration {
            switch self {
            case .article: return AcademyMarkdownConfig.config
            case .gitRelease: return ReleaseNotesMarkdownConfig.config
            }
        }
    }

    enum State {
        case loading
        case loaded(viewItems: [MarkdownBlockViewItem])
        case failed(error: Error)
    }

    enum LinkAction: Equatable {
        case pushMarkdown(url: URL)
        case external(url: URL)
    }

    private struct GitHubRelease: Decodable {
        let body: String
    }
}
