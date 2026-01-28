import Combine
import Foundation

class BirthdayInputViewModel: ObservableObject {
    private let provider: IBirthdayInputProvider
    private let onEnterBirthdayHeight: (Int) -> Void
    private let lastHeight: Int
    private let initialHeight: Int?

    @Published var heightString: String = "" {
        didSet {
            height = Int(heightString)
            syncState()
        }
    }

    @Published var state: State = .valid
    @Published var date: Date?

    private var height: Int?

    init(initialHeight: Int?, provider: IBirthdayInputProvider, onEnterBirthdayHeight: @escaping (Int) -> Void) {
        self.provider = provider
        self.onEnterBirthdayHeight = onEnterBirthdayHeight
        lastHeight = provider.lastBlockHeight
        self.initialHeight = initialHeight

        syncState()
    }

    private var defaultHeight: Int {
        initialHeight ?? lastHeight
    }

    private func syncState() {
        date = resolveDate()

        if let initialHeight {
            if heightString.isEmpty {
                state = .notModified
            } else if let height, height <= lastHeight {
                if height == initialHeight {
                    state = .notModified
                } else {
                    state = .valid
                }
            } else {
                state = .invalid
            }
        } else {
            if heightString.isEmpty {
                state = .valid
            } else if let height, height <= lastHeight {
                state = .valid
            } else {
                state = .invalid
            }
        }
    }

    private func resolveDate() -> Date? {
        if let height, height <= lastHeight {
            return provider.date(height: height)
        }

        if heightString.isEmpty {
            return provider.date(height: defaultHeight)
        }

        return nil
    }
}

extension BirthdayInputViewModel {
    var buttonTitle: String {
        switch state {
        case .valid, .notModified: return initialHeight == nil ? "button.done".localized : "birthday_input.rescan".localized
        case .invalid: return "birthday_input.invalid_block".localized
        }
    }

    var buttonEnabled: Bool {
        switch state {
        case .valid: return true
        case .notModified, .invalid: return false
        }
    }

    var placeholder: String {
        String(defaultHeight)
    }

    var defaultDate: Date {
        provider.date(height: defaultHeight)
    }

    var startDate: Date {
        provider.date(height: 1)
    }

    func handle(date: Date?) {
        guard let date else {
            return
        }

        heightString = String(provider.height(date: min(date, Date())))
    }

    func apply() {
        if heightString.isEmpty {
            onEnterBirthdayHeight(defaultHeight)
        } else if let height {
            onEnterBirthdayHeight(height)
        }
    }
}

extension BirthdayInputViewModel {
    enum State {
        case valid
        case invalid
        case notModified
    }
}
