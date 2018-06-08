import UIKit

class BackupIntroController: UIViewController {

    let viewDelegate: BackupViewDelegate

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var laterButton: UIButton?
    @IBOutlet weak var backupButton: UIButton?

    init(viewDelegate: BackupViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: BackupIntroController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel?.text = "backup.intro.title".localized
        subtitleLabel?.text = "backup.intro.subtitle".localized
        laterButton?.setTitle("backup.intro.later".localized, for: .normal)
        backupButton?.setTitle("backup.intro.backup_now".localized, for: .normal)
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
