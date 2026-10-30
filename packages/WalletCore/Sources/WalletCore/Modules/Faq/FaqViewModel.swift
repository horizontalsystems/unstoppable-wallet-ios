import Combine
import Foundation
import HsExtensions
import HsToolKit

@MainActor
final class FaqViewModel: ObservableObject {
    private let networkManager = Core.shared.networkManager
    private let reachabilityManager = Core.shared.reachabilityManager
    private let languageManager = LanguageManager.shared
    private var tasks = Set<AnyTask>()
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var state: State = .loading

    init() {
        sync()

        reachabilityManager.$isReachable
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reachable in
                MainActor.assumeIsolated {
                    guard reachable, let self, case .failed = self.state else {
                        return
                    }

                    self.sync()
                }
            }
            .store(in: &cancellables)
    }

    private func sync() {
        tasks = Set()

        state = .loading

        let language = languageManager.currentLanguage
        let fallbackLanguage = LanguageManager.fallbackLanguage

        Task { [weak self, networkManager] in
            do {
                let sections = try await Self.loadSections(
                    networkManager: networkManager,
                    language: language,
                    fallbackLanguage: fallbackLanguage
                )

                guard !Task.isCancelled else {
                    return
                }

                self?.state = .loaded(sections: sections)
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                self?.state = .failed(error: error)
            }
        }
        .store(in: &tasks)
    }

    /// Runs off the main actor: network fetch, JSON decoding and section building
    private nonisolated static func loadSections(networkManager: NetworkManager, language: String, fallbackLanguage: String) async throws -> [Section] {
        let faqSections: [FaqSection] = try await networkManager.fetch(url: AppConfig.faqIndexUrl)

        try Task.checkCancellation()

        return faqSections.compactMap { section(faqSection: $0, language: language, fallbackLanguage: fallbackLanguage) }
    }

    private nonisolated static func section(faqSection: FaqSection, language: String, fallbackLanguage: String) -> Section? {
        guard let title = faqSection.titles[language] ?? faqSection.titles[fallbackLanguage] else {
            return nil
        }

        let items = faqSection.items.compactMap { item -> Item? in
            guard let faq = item[language] ?? item[fallbackLanguage] else {
                return nil
            }

            return Item(text: faq.text, url: URL(string: faq.fileUrl, relativeTo: AppConfig.faqIndexUrl))
        }

        return Section(title: title, items: items)
    }
}

extension FaqViewModel {
    func onRetry() {
        sync()
    }
}

extension FaqViewModel {
    enum State {
        case loading
        case loaded(sections: [Section])
        case failed(error: Error)
    }

    struct Section: Hashable {
        let title: String
        let items: [Item]
    }

    struct Item: Hashable {
        let text: String
        let url: URL?
    }
}
