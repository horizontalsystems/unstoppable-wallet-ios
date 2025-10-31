import SwiftUI

struct SpinningModifier: ViewModifier {
    let duration: Double
    @State private var currentAngle: Double = 0

    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(currentAngle))
            .animation(
                .linear(duration: duration).repeatForever(autoreverses: false),
                value: currentAngle
            )
            .onAppear {
                currentAngle = 360
            }
    }
}

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
