import UIKit
import GrouviActionSheet

class BackupNavigationController: UINavigationController {

    let viewDelegate: IBackupViewDelegate

    init(viewDelegate: IBackupViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: nil, bundle: nil)

        navigationBar.barStyle = .blackTranslucent
        navigationBar.tintColor = .cryptoYellow
        navigationBar.prefersLargeTitles = true
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

    func onValidateSuccess() {
        if let confirmationController = topViewController as? BackupConfirmationController {
            confirmationController.showConfirmAlert()
        }
    }

    func showWarning() {
        BackupConfirmationAlertModel.show(from: self) { [weak self] success in
            if success {
                self?.viewDelegate.onConfirm()
            }
        }
    }

    func showUnlock() {
        let canLock = App.shared.wordsManager.isLoggedIn && PinManager.shared.isPinned
        if canLock {
            UnlockPinRouter.module(cancelable: true) { [weak self] in
                self?.viewDelegate.onUnlock()
            }
        } else {
            viewDelegate.onUnlock()
        }

    }

}
