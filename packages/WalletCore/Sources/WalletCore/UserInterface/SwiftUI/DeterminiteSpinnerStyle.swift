import SwiftUI

struct DeterminiteSpinnerStyle: ProgressViewStyle {
    private let strokeWidth: CGFloat = 2

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Circle()
                .inset(by: strokeWidth / 2)
                .stroke(Color.themeAndy, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            Circle()
                .inset(by: strokeWidth / 2)
                .trim(from: 0.0, to: CGFloat(configuration.fractionCompleted ?? 0))
                .stroke(Color.themeLeah, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: configuration.fractionCompleted)
        }
    }
}
