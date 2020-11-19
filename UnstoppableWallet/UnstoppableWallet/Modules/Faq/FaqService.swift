import RxSwift
import HsToolKit
import LanguageKit

class FaqService {
    private let appConfigProvider: IAppConfigProvider
    private let repository: FaqRepository
    private let languageManager: LanguageManager

    init(appConfigProvider: IAppConfigProvider, repository: FaqRepository, languageManager: LanguageManager) {
        self.appConfigProvider = appConfigProvider
        self.repository = repository
        self.languageManager = languageManager
    }

    private func items(dictionaries: [[String: Faq]]) -> [Item] {
        let faqIndexUrl = appConfigProvider.faqIndexUrl

        return dictionaries.compactMap { dictionary in
            guard let faq = dictionary[languageManager.currentLanguage] ?? dictionary[LanguageManager.fallbackLanguage] else {
                return nil
            }

            return Item(
                    text: faq.text,
                    url: URL(string: faq.fileUrl, relativeTo: faqIndexUrl)
            )
        }
    }

}

extension FaqService {

    var faqObservable: Observable<DataStatus<[Item]>> {
        repository.faqObservable.map { [weak self] dataState in
            dataState.map { [weak self] in
                self?.items(dictionaries: $0) ?? []
            }
        }
    }

}

extension FaqService {

    struct Item {
        let text: String
        let url: URL?
    }

}
