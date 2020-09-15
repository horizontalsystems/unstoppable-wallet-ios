import UIKit

struct RestoreWordsModule {

    static func viewController(restoreView: RestoreView, wordCount: Int) -> UIViewController {
        let service = RestoreWordsService(wordCount: wordCount, wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let viewModel = RestoreWordsViewModel(service: service)
        return RestoreWordsViewController(restoreView: restoreView, viewModel: viewModel)
    }

}
