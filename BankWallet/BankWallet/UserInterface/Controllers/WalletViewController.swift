import UIKit

class WalletViewController: UIViewController {
    private let gradient: Bool

    init(gradient: Bool = true) {
        self.gradient = gradient

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .fullScreen

        App.shared.debugLogger?.add(log: "Init \(String(describing: type(of: self)))")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        App.shared.debugLogger?.add(log: "Load \(String(describing: type(of: self)))")

        guard gradient else {
            return
        }

        let bounds = view.bounds
        let gradientStartY = 160 / bounds.height
        let gradientImageView = UIImageView(image: UIImage.gradientImage(
                fromColor: AppTheme.controllerBackgroundFromGradient,
                toColor: AppTheme.controllerBackgroundToGradient,
                size: CGSize(width: view.bounds.size.width, height: view.bounds.size.height),
                startPoint: CGPoint(x: 0.5, y: gradientStartY)))
        view = gradientImageView
        gradientImageView.isUserInteractionEnabled = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        App.theme.statusBarStyle
    }

    deinit {
        App.shared.debugLogger?.add(log: "Deinit \(String(describing: type(of: self)))")
    }

}
