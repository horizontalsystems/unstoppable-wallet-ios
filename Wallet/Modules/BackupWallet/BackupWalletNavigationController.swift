import UIKit

class BackupWalletNavigationController: UINavigationController {

    let viewDelegate: BackupWalletViewDelegate

    init(viewDelegate: BackupWalletViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BackupWalletNavigationController.self), bundle: nil)

        isNavigationBarHidden = true
        viewControllers = [BackupWalletIntroController(viewDelegate: viewDelegate)]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

extension BackupWalletNavigationController: BackupWalletViewProtocol {

    func show(words: [String]) {
        pushViewController(BackupWalletWordsController(words: words, viewDelegate: viewDelegate), animated: true)
    }

    func showConfirmation(withIndexes indexes: [Int]) {
        pushViewController(BackupWalletConfirmationController(indexes: indexes, viewDelegate: viewDelegate), animated: true)
    }

    func hideWords() {
        popViewController(animated: true)
    }

    func hideConfirmation() {
        popViewController(animated: true)
    }

    func showValidationFailure() {
        if let confirmationController = topViewController as? BackupWalletConfirmationController {
            confirmationController.showValidationFailure()
        }
    }

}
