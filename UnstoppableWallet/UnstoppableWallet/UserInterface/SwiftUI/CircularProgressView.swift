import SwiftUI

struct CircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.themeSteel20,
                    lineWidth: 1.5
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.themeJacob,
                    style: StrokeStyle(
                        lineWidth: 1.5,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 16, height: 16)
    }
}
