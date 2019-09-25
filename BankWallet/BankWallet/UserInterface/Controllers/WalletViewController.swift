import UIKit

class WalletViewController: UIViewController {
    private let gradient: Bool

    init(gradient: Bool = true) {
        self.gradient = gradient

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

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

}
