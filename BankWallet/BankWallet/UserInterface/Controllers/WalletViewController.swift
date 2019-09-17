import UIKit

class WalletViewController: UIViewController {
    private let opaque: Bool

    init(opaque: Bool = true) {
        self.opaque = opaque

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard opaque else {
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

}
