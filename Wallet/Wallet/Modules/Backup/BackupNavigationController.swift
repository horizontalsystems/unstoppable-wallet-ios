import UIKit

class BackupNavigationController: UINavigationController {

    let viewDelegate: BackupViewDelegate

    init(viewDelegate: BackupViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BackupNavigationController.self), bundle: nil)

        isNavigationBarHidden = true
        viewControllers = [BackupIntroController(viewDelegate: viewDelegate)]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

extension BackupNavigationController: BackupViewProtocol {

    func show(words: [String]) {
        pushViewController(BackupWordsController(words: words, viewDelegate: viewDelegate), animated: true)
    }

    func showConfirmation(withIndexes indexes: [Int]) {
        pushViewController(BackupConfirmationController(indexes: indexes, viewDelegate: viewDelegate), animated: true)
    }

    func hideWords() {
        popViewController(animated: true)
    }

    func hideConfirmation() {
        popViewController(animated: true)
    }

    func showValidationFailure() {
        if let confirmationController = topViewController as? BackupConfirmationController {
            confirmationController.showValidationFailure()
        }
    }

}
