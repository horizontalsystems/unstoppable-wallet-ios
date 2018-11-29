import UIKit

class GuestViewController: UIViewController {

    let delegate: IGuestViewDelegate

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var createButton: UIButton?
    @IBOutlet weak var restoreButton: UIButton?

    init(delegate: IGuestViewDelegate) {
        self.delegate = delegate

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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        delegate.willAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        delegate.willDisappear()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBAction func createNewWalletDidTap() {
        delegate.createWalletDidClick()
    }

    @IBAction func restoreWalletDidTap() {
        delegate.restoreWalletDidClick()
    }

}
