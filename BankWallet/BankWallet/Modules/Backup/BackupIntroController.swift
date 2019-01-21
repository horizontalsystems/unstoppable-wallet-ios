import UIKit

class BackupIntroController: UIViewController {

    let delegate: IBackupViewDelegate

    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var laterButton: UIButton?
    @IBOutlet weak var backupButton: UIButton?

    init(delegate: IBackupViewDelegate) {
        self.delegate = delegate

        super.init(nibName: String(describing: BackupIntroController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = AppTheme.controllerBackground

        title = "backup.intro.title".localized

        laterButton?.setBackgroundColor(color: BackupTheme.laterButtonBackground, forState: .normal)
        subtitleLabel?.text = "backup.intro.subtitle".localized
        laterButton?.setTitle("backup.intro.later".localized, for: .normal)
        backupButton?.setTitle("backup.intro.backup_now".localized, for: .normal)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @IBAction func backupDidTap() {
        delegate.showWordsDidClick()
    }

    @IBAction func cancelDidTap() {
        delegate.cancelDidClick()
    }

}
