import UIKit

class BackupWalletIntroController: UIViewController {

    let viewDelegate: BackupWalletViewDelegate

    init(viewDelegate: BackupWalletViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BackupWalletIntroController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func backupDidTap() {
        viewDelegate.showWordsDidTap()
    }

    @IBAction func cancelDidTap() {
        viewDelegate.cancelDidTap()
    }

}
