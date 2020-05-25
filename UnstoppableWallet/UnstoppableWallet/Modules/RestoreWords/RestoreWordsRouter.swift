import UIKit

class RestoreWordsRouter {

    static func module(handler: IRestoreAccountTypeHandler, wordsCount: Int) -> UIViewController {
        let presenter = RestoreWordsPresenter(handler: handler, wordsCount: wordsCount, wordsManager: App.shared.wordsManager, appConfigProvider: App.shared.appConfigProvider)
        let viewController = RestoreWordsViewController(delegate: presenter)

        presenter.view = viewController

        return viewController
    }

}
