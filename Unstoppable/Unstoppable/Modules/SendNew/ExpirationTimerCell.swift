import Combine
import Foundation
import SwiftUI

struct ExpirationTimerCell: View {
    @StateObject private var viewModel: ExpirationTimerViewModel
    private let title: CustomStringConvertible

    init(title: CustomStringConvertible, expirationDate: Date) {
        self.title = title
        _viewModel = StateObject(wrappedValue: ExpirationTimerViewModel(expirationDate: expirationDate))
    }

    var body: some View {
        Cell(
            style: .secondary,
            middle: {
                MiddleTextIcon(text: title).styled(title)
            },
            right: {
                RightMultiText(subtitle: viewModel.text.styled(.primary))
            }
        )
    }
}

class ExpirationTimerViewModel: ObservableObject {
    @Published var text: ComponentText = .init(text: "", colorStyle: .yellow)

    private let expirationDate: Date
    private var timer: Timer?

    init(expirationDate: Date) {
        self.expirationDate = expirationDate
        tick()
    }

    deinit {
        timer?.invalidate()
    }

    private func tick() {
        let remaining = max(0, Int(expirationDate.timeIntervalSinceNow))
        text = Self.format(remaining: remaining)

        guard remaining > 0 else {
            print("[timer] tick remaining=0 → stop (expired)")
            return
        }

        // Align next tick to wall clock: snap to next minute boundary while > 60s, else 1s.
        let nextInterval: TimeInterval
        if remaining > 60 {
            let secondsInMinute = remaining % 60
            nextInterval = TimeInterval(secondsInMinute == 0 ? 60 : secondsInMinute)
        } else {
            nextInterval = 1
        }

        print("[timer] tick remaining=\(remaining)s text=\(text.text) next=\(nextInterval)s")

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: nextInterval, repeats: false) { [weak self] _ in
            self?.tick()
        }
    }

    static func format(remaining: Int) -> ComponentText {
        if remaining == 0 {
            return ComponentText(text: "0s", colorStyle: .red)
        }
        if remaining < 60 {
            return ComponentText(text: "\(remaining)s", colorStyle: .yellow)
        }
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        let text = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
        return ComponentText(text: text, colorStyle: .yellow)
    }
}
