import UIKit

class BackupNavigationController: UINavigationController {

    let viewDelegate: IBackupViewDelegate

    init(viewDelegate: IBackupViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BackupNavigationController.self), bundle: nil)

        isNavigationBarHidden = true
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

    func showConfirmation(withIndexes indexes: [Int]) {
        pushViewController(BackupConfirmationController(indexes: indexes, delegate: viewDelegate), animated: true)
    }

    func hideWords() {
        popViewController(animated: true)
    }

    func hideConfirmation() {
        popViewController(animated: true)
    }

    func showConfirmationError() {
        if let confirmationController = topViewController as? BackupConfirmationController {
            confirmationController.showValidationFailure()
        }
    }

}
