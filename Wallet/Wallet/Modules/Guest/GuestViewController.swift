import UIKit

class GuestViewController: UIViewController {

    let viewDelegate: GuestViewDelegate

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var createButton: UIButton?
    @IBOutlet weak var restoreButton: UIButton?

    init(viewDelegate: GuestViewDelegate) {
        self.viewDelegate = viewDelegate

        super.init(nibName: String(describing: GuestViewController.self), bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel?.text = "guest.title".localized
        subtitleLabel?.text = "guest.subtitle".localized
        createButton?.setTitle("guest.create_wallet".localized, for: .normal)
        restoreButton?.setTitle("guest.restore_wallet".localized, for: .normal)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func createNewWalletDidTap() {
        viewDelegate.createNewWalletDidTap()
    }

    @IBAction func restoreWalletDidTap() {
        viewDelegate.restoreWalletDidTap()
    }

}
