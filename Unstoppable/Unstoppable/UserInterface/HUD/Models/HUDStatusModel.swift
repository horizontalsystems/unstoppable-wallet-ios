import UIKit

public protocol HUDStatusViewConfig {
    var imageInsets: UIEdgeInsets { get }
    var textInsets: UIEdgeInsets { get }
    var imageTopPadding: CGFloat { get }
    var imageBottomPadding: CGFloat { get }
    var titleBottomPadding: CGFloat { get }
}

public class HUDStatusModel: HUDStatusViewConfig {
    public var successImage: UIImage?
    public var infoImage: UIImage?
    public var errorImage: UIImage?
    public var cancelImage: UIImage?

    public var activityIndicatorStyle: UIActivityIndicatorView.Style = .whiteLarge
    public var activityIndicatorColor: UIColor = .gray

    public var customProgressValue: Float? = 0
    public var customProgressRadius: CGFloat = 24
    public var customProgressColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
    public var customDonutColor: UIColor? = nil
    public var customProgressLineWidth: CGFloat = 8
    public var customProgressDuration: TimeInterval = 1
    public var customShowCancelInterval: TimeInterval? = 3

    public var imageTintColor: UIColor?
    public var imageContentMode = UIView.ContentMode.center

    public var titleLabelFont: UIFont = .systemFont(ofSize: 17)
    public var titleLabelColor: UIColor = .black
    public var titleLabelAlignment: NSTextAlignment = .center
    public var titleLabelLinesCount: Int = 0

    public var subtitleLabelFont: UIFont = .systemFont(ofSize: 15)
    public var subtitleLabelColor: UIColor = .black
    public var subtitleLabelAlignment: NSTextAlignment = .center
    public var subtitleLabelLinesCount: Int = 2

    public var showTimeInterval: TimeInterval?
    public var dismissTimeInterval: TimeInterval?

    // HUD status view constraints parameters
    public var imageInsets: UIEdgeInsets = HUDStatusViewTheme.imageInsets
    public var textInsets: UIEdgeInsets = HUDStatusViewTheme.textInsets
    public var imageTopPadding: CGFloat = HUDStatusViewTheme.imageTopPadding
    public var imageBottomPadding: CGFloat = HUDStatusViewTheme.imageBottomPadding
    public var titleBottomPadding: CGFloat = HUDStatusViewTheme.titleBottomPadding

    init() {
        successImage = UIImage(named: "success", in: nil, compatibleWith: nil)
        infoImage = UIImage(named: "info", in: nil, compatibleWith: nil)
        errorImage = UIImage(named: "error", in: nil, compatibleWith: nil)
        cancelImage = UIImage(named: "error", in: nil, compatibleWith: nil)
    }
}
