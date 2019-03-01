import UIKit

class GuestViewController: UIViewController {
    private let delegate: IGuestViewDelegate

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var createButton: UIButton?
    @IBOutlet weak var importButton: UIButton?
    @IBOutlet weak var versionLabel: UILabel?

    init(delegate: IGuestViewDelegate) {
        self.delegate = delegate

        super.init(nibName: String(describing: GuestViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate.viewDidLoad()

        titleLabel?.text = "guest.title".localized
        createButton?.setTitle("guest.create_wallet".localized, for: .normal)
        importButton?.setTitle("guest.restore_wallet".localized, for: .normal)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return AppTheme.statusBarStyle
    }

    @IBAction func createNewWalletDidTap() {
        delegate.createWalletDidClick()
    }

    @IBAction func restoreWalletDidTap() {
        delegate.restoreWalletDidClick()
    }

}

extension GuestViewController: IGuestView {

    func set(appVersion: String) {
        versionLabel?.text = appVersion
    }

}
