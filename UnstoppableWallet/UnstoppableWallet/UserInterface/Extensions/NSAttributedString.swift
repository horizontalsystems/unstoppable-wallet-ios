import UIKit

extension NSAttributedString {

    public func height(containerWidth: CGFloat) -> CGFloat {
        size(containerWidth: containerWidth).height
    }

    public func size(containerWidth: CGFloat) -> CGSize {
        let size = self.boundingRect(
                with: CGSize(width: containerWidth, height: .greatestFiniteMagnitude),
                options: [.usesFontLeading, .usesLineFragmentOrigin],
                context: nil
        ).size

        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }

}
