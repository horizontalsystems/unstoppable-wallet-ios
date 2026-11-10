import SwiftUI

/// The indeterminate ring around a pending transaction glyph: a faint track and an amber arc
/// fading out along its length, rotating continuously. The caller sets its frame.
struct PendingLoaderRing: View {
    /// the 2pt stroke of the Figma "loader pending gradient"
    private let strokeWidth: CGFloat = .margin2

    var body: some View {
        ZStack {
            Circle()
                .inset(by: strokeWidth / 2)
                .stroke(Color.themeAndy.opacity(0.2), lineWidth: strokeWidth)

            // the Figma arc: 270 degrees from 3 o'clock, clockwise to 12 o'clock
            Circle()
                .inset(by: strokeWidth / 2)
                .trim(from: 0, to: 0.75)
                .stroke(
                    // the Figma gradient: Jacob from its 0.2026 stop, transparent from 0.5952, bottom-left to top-right
                    LinearGradient(
                        stops: [
                            .init(color: .themeBrand, location: 0.2026),
                            .init(color: .themeBrand.opacity(0), location: 0.5952),
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt)
                )
        }
        .spinning(duration: PendingAnimation.period)
    }
}

/// The clock a pending row animates by: the ring turns once per `period`, and the pending subtitle fades
/// once per `period`, both read from the same date, so they stay in step
enum PendingAnimation {
    static let period: Double = 1.0

    /// 0 at the start of a turn, 1 halfway, back to 0 at its end; the turn's progress is computed
    /// as `ContinuousSpinningModifier` computes the ring's angle
    static func phase(date: Date) -> Double {
        let progress = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
        return (1 - cos(2 * .pi * progress)) / 2
    }
}
