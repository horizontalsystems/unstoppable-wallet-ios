import UIKit
import GrouviActionSheet

class BackupNavigationController: UINavigationController {

    let viewDelegate: IBackupViewDelegate

    init(viewDelegate: IBackupViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: nil, bundle: nil)

        navigationBar.barStyle = AppTheme.navigationBarStyle
        navigationBar.tintColor = AppTheme.navigationBarTintColor
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
        BackupConfirmationViewController.show(from: self) { [weak self] in
            self?.viewDelegate.onConfirm()
        }
    }

}
