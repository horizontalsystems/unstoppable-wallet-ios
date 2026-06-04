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
            return
        }

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.tick()
        }
    }

    static func format(remaining: Int) -> ComponentText {
        let text = Duration.seconds(remaining).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .narrow))
        return ComponentText(text: text, colorStyle: remaining == 0 ? .red : .yellow)
    }
}
