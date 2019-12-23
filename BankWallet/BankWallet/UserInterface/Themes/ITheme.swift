import UIKit

protocol ITheme {
    var hudBlurStyle: UIBlurEffect.Style { get }
    var keyboardAppearance: UIKeyboardAppearance { get }
    var navigationBarStyle: UIBarStyle { get }
    var statusBarStyle: UIStatusBarStyle { get }

    var colorJacob: UIColor { get }
    var colorRemus: UIColor { get }
    var colorLucian: UIColor { get }
    var colorOz: UIColor { get }
    var colorLeah: UIColor { get }
    var colorJeremy: UIColor { get }
    var colorElena: UIColor { get }
    var colorLawrence: UIColor { get }
    var colorLawrencePressed: UIColor { get }
    var colorClaude: UIColor { get }
    var colorAndy: UIColor { get }
    var colorTyler: UIColor { get }
    var colorNina: UIColor { get }
    var colorHelsing: UIColor { get }

    var alphaSecondaryButtonGradient: CGFloat { get }
}
