import UIKit

class BackupIntroController: UIViewController {

    let viewDelegate: BackupViewDelegate

    init(viewDelegate: BackupViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BackupIntroController.self), bundle: nil)
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
