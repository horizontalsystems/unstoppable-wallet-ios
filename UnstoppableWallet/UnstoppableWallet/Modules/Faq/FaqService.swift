import Foundation
import RxSwift
import HsToolKit
import LanguageKit

class FaqService {
    private let appConfigProvider: AppConfigProvider
    private let repository: FaqRepository
    private let languageManager: LanguageManager

    init(appConfigProvider: AppConfigProvider, repository: FaqRepository, languageManager: LanguageManager) {
        self.appConfigProvider = appConfigProvider
        self.repository = repository
        self.languageManager = languageManager
    }

    private func sectionItems(sections: [FaqSection]) -> [SectionItem] {
        let faqIndexUrl = appConfigProvider.faqIndexUrl

        return sections.compactMap { section in
            guard let title = section.titles[languageManager.currentLanguage] ?? section.titles[LanguageManager.fallbackLanguage] else {
                return nil
            }

            let items = section.items.compactMap { item -> Item? in
                guard let faq = item[languageManager.currentLanguage] ?? item[LanguageManager.fallbackLanguage] else {
                    return nil
                }

                return Item(
                        text: faq.text,
                        url: URL(string: faq.fileUrl, relativeTo: faqIndexUrl)
                )
            }

            return SectionItem(title: title, items: items)
        }
    }

}

extension FaqService {

    var faqObservable: Observable<DataStatus<[SectionItem]>> {
        repository.faqObservable.map { [weak self] dataState in
            dataState.map { [weak self] in
                self?.sectionItems(sections: $0) ?? []
            }
        }
    }

}

extension FaqService {

    struct SectionItem {
        let title: String
        let items: [Item]
    }

    struct Item {
        let text: String
        let url: URL?
    }

}
