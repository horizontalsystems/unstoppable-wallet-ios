import SwiftUI

struct ContinuousSpinningModifier: ViewModifier {
    let duration: Double

    func body(content: Content) -> some View {
        TimelineView(.animation) { timeline in
            let angle = (timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: duration) / duration) * 360

            content
                .rotationEffect(.degrees(angle))
        }
    }
}

extension View {
    func spinning(duration: Double = 2.0) -> some View {
        modifier(ContinuousSpinningModifier(duration: duration))
    }
}
