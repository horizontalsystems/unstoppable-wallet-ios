import UIKit

extension String {

    public func height(forContainerWidth containerWidth: CGFloat, font: UIFont) -> CGFloat {
        return size(containerWidth: containerWidth, font: font).height
    }

    public func size(containerWidth: CGFloat, font: UIFont) -> CGSize {
        return (self as NSString).boundingRect(
                with: CGSize(width: containerWidth, height: .greatestFiniteMagnitude),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                attributes: [NSAttributedStringKey.font: font],
                context: nil).size
    }

}
