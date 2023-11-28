import UIKit

public extension NSAttributedString {
    func height(containerWidth: CGFloat) -> CGFloat {
        size(containerWidth: containerWidth).height
    }

    func size(containerWidth: CGFloat) -> CGSize {
        let size = boundingRect(
            with: CGSize(width: containerWidth, height: .greatestFiniteMagnitude),
            options: [.usesFontLeading, .usesLineFragmentOrigin],
            context: nil
        ).size

        return CGSize(width: ceil(size.width), height: ceil(size.height))
    }
}
