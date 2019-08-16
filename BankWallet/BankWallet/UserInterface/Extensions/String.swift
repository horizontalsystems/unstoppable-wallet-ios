import UIKit

extension String {

    public func height(forContainerWidth containerWidth: CGFloat, font: UIFont) -> CGFloat {
        let height = size(containerWidth: containerWidth, font: font).height
        return ceil(height)
    }

    public func size(containerWidth: CGFloat, font: UIFont) -> CGSize {
        return (self as NSString).boundingRect(
                with: CGSize(width: containerWidth, height: .greatestFiniteMagnitude),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                attributes: [NSAttributedString.Key.font: font],
                context: nil).size
    }

}
