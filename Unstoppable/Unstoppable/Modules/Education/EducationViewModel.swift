import Combine
import Foundation
import HsExtensions
import ObjectMapper

class EducationViewModel: ObservableObject {
    private let networkManager = Core.shared.networkManager
    private let languageManager = LanguageManager.shared
    private var tasks = Set<AnyTask>()

    @Published var state: State = .loading

    init() {
        sync()
    }

    private func sync() {
        tasks = Set()

        state = .loading

        Task { [weak self, networkManager] in
            do {
                let educationCategories: [EducationCategory] = try await networkManager.fetch(url: AppConfig.eduIndexUrl)
                let categories = educationCategories.compactMap { self?.category(educationCategory: $0) }

                await MainActor.run { [weak self] in
                    self?.state = .loaded(categories: categories)
                }
            } catch {
                print(error)
                await MainActor.run { [weak self] in
                    self?.state = .failed(error: error)
                }
            }
        }
        .store(in: &tasks)
    }

    private func category(educationCategory: EducationCategory) -> Category? {
        guard let title = educationCategory.title(language: languageManager.currentLanguage, fallbackLanguage: LanguageManager.fallbackLanguage) else {
            return nil
        }

        return Category(
            title: title,
            sections: educationCategory.sections.compactMap { section(educationSection: $0) }
        )
    }

    private func section(educationSection: EducationSection) -> Section? {
        guard let title = educationSection.title(language: languageManager.currentLanguage, fallbackLanguage: LanguageManager.fallbackLanguage) else {
            return nil
        }

        return Section(
            title: title,
            items: educationSection.items(language: languageManager.currentLanguage, fallbackLanguage: LanguageManager.fallbackLanguage).compactMap { item in
                guard let url = URL(string: item.markdown, relativeTo: AppConfig.eduIndexUrl) else {
                    return nil
                }

                return Item(title: item.title, url: url)
            }
        )
    }
}

extension EducationViewModel {
    func onRetry() {
        sync()
    }
}

extension EducationViewModel {
    struct Section {
        let title: String
        let items: [Item]
    }

    struct Category {
        let title: String
        let sections: [Section]
    }

    struct Item {
        let title: String
        let url: URL
    }

    enum State {
        case loading
        case loaded(categories: [Category])
        case failed(error: Error)
    }
}

extension EducationViewModel {
    struct EducationCategory: ImmutableMappable {
        private let titles: [String: String]
        let sections: [EducationSection]

        init(map: Map) throws {
            titles = try map.value("category")
            sections = try map.value("sections")
        }

        func title(language: String, fallbackLanguage: String) -> String? {
            titles[language] ?? titles[fallbackLanguage]
        }
    }

    struct EducationSection: ImmutableMappable {
        private let titles: [String: String]
        private let items: [[String: EducationItem]]

        init(map: Map) throws {
            titles = try map.value("title")
            items = try map.value("items", using: ItemTransform())
        }

        func title(language: String, fallbackLanguage: String) -> String? {
            titles[language] ?? titles[fallbackLanguage]
        }

        func items(language: String, fallbackLanguage: String) -> [EducationItem] {
            items.compactMap { map in
                map[language] ?? map[fallbackLanguage]
            }
        }

        class ItemTransform: TransformType {
            typealias Object = [[String: EducationItem]]
            typealias JSON = Any

            func transformFromJSON(_ value: Any?) -> [[String: EducationItem]]? {
                guard let items = value as? [[String: Any]] else {
                    return nil
                }

                do {
                    return try items.map { item in
                        try item.mapValues { itemJson in
                            try EducationItem(JSONObject: itemJson)
                        }
                    }
                } catch {
                    return nil
                }
            }

            func transformToJSON(_: [[String: EducationItem]]?) -> Any? {
                fatalError("transformToJSON(_:) has not been implemented")
            }
        }
    }

    struct EducationItem: ImmutableMappable {
        let title: String
        let markdown: String

        init(map: Map) throws {
            title = try map.value("title")
            markdown = try map.value("markdown")
        }
    }
}
