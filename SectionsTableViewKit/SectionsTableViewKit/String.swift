import UIKit
//todo extract this to GrouviExtensions
extension String {

    public func heightt(forContainerWidth containerWidth: CGFloat, font: UIFont) -> CGFloat {
        return sizee(containerWidth: containerWidth, font: font).height
    }

    public func sizee(containerWidth: CGFloat, font: UIFont) -> CGSize {
        return (self as NSString).boundingRect(
                with: CGSize(width: containerWidth, height: .greatestFiniteMagnitude),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                attributes: [NSAttributedStringKey.font: font],
                context: nil).size
    }

}
