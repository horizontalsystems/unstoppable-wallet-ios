import UIKit

class WalletViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

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
