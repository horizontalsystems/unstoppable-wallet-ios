import ThemeKit
import ComponentKit

class WalletConnectErrorViewController: ThemeViewController {
    private let error: Error
    private weak var sourceViewController: UIViewController?

    private let errorView = RequestErrorViewNew()
    private let closeButton = ThemeButton()

    init(error: Error, sourceViewController: UIViewController?) {
        self.error = error
        self.sourceViewController = sourceViewController

        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "wallet_connect.title".localized

        view.addSubview(errorView)
        errorView.snp.makeConstraints { maker in
            maker.top.bottom.equalToSuperview()
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin4x)
        }

        errorView.bind(image: UIImage(named: "close_48"), text: error.smartDescription)

        view.addSubview(closeButton)
        closeButton.snp.makeConstraints { maker in
            maker.leading.trailing.equalToSuperview().inset(CGFloat.margin6x)
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(CGFloat.margin6x)
            maker.height.equalTo(CGFloat.heightButton)
        }

        closeButton.apply(style: .primaryGray)
        closeButton.setTitle("button.close".localized, for: .normal)
        closeButton.addTarget(self, action: #selector(onClose), for: .touchUpInside)
    }

    @objc private func onClose() {
        sourceViewController?.dismiss(animated: true)
    }

}
