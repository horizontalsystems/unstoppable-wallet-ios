import UIKit
import ActionSheet

class BackupNavigationController: WalletNavigationController {

    let viewDelegate: IBackupViewDelegate

    init(viewDelegate: IBackupViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: nil, bundle: nil)

        viewControllers = [BackupIntroController(delegate: viewDelegate)]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension BackupNavigationController: IBackupView {

    func show(words: [String]) {
        pushViewController(BackupWordsController(words: words, delegate: viewDelegate), animated: true)
    }

    func showWordsConfirmation(withIndexes indexes: [Int]) {
        pushViewController(BackupConfirmationController(indexes: indexes, delegate: viewDelegate), animated: true)
    }

    func showWordsConfirmation(error: Error) {
        if let confirmationController = topViewController as? BackupConfirmationController {
            confirmationController.showValidation(error: error)
        }
    }

}
