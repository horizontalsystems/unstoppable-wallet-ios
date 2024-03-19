import SwiftUI

struct MultiSwapCircularProgressView: View {
    let nextQuoteTime: Double
    let autoRefreshDuration: Double

    @State private var progress: Double = 0

    private let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

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
        .onAppear {
            let timeLeft = max(0, nextQuoteTime - Date().timeIntervalSince1970)
            progress = timeLeft / autoRefreshDuration
        }
        .onReceive(timer) { _ in
            let timeLeft = max(0, nextQuoteTime - Date().timeIntervalSince1970)
            withAnimation(.linear(duration: 0.1)) {
                progress = timeLeft / autoRefreshDuration
            }
        }
    }
}
