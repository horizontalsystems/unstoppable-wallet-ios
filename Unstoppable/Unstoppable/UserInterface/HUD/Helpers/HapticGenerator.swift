import UIKit

public protocol HUDFeedbackGenerator {
    func notification(_ notification: HapticNotificationType)
}

public class HapticGenerator: HUDFeedbackGenerator {
    public static let instance = HapticGenerator()
    let notificationGenerator = UINotificationFeedbackGenerator()
    var impactStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light
    var impactGenerator = UIImpactFeedbackGenerator(style: .light)

    public func notification(_ notification: HapticNotificationType) {
        switch notification {
        case .error: notificationGenerator.notificationOccurred(.error)
        case .success: notificationGenerator.notificationOccurred(.success)
        case .warning: notificationGenerator.notificationOccurred(.warning)
        case let .feedback(style): if impactStyle != style {
                impactGenerator = UIImpactFeedbackGenerator(style: style)
            }
            impactGenerator.impactOccurred()
        }
    }
}
