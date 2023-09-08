import ComponentKit
import Foundation

protocol IEventHandler {
    func handle(event: Any, eventType: EventHandler.EventType) async throws
}

class EventHandler {
    private var eventHandlers = [IEventHandler]()

    func append(handler: IEventHandler) {
        eventHandlers.append(handler)
    }

    func prepend(handler: IEventHandler) {
        if eventHandlers.count > 0 {
            eventHandlers.insert(handler, at: 0)
        } else {
            eventHandlers.append(handler)
        }
    }

    @MainActor private func show(error: Error) {
        HudHelper.instance.show(banner: .error(string: error.smartDescription))
    }
}

extension EventHandler: IEventHandler {
    func handle(event: Any, eventType: EventHandler.EventType = .all) async throws {
        var lastError: Error?
        for handler in eventHandlers {
            do {
                try await handler.handle(event: event, eventType: eventType)
            } catch {
                lastError = error
            }
        }

        guard let lastError else {
            return
        }

        switch lastError {
        case HandleError.noSuitableHandler: await show(error: lastError)
        default: throw lastError
        }
    }
}

extension EventHandler {
    struct EventType: OptionSet {
        let rawValue: UInt8
        static let all: EventType = [.walletConnectDeepLink, .walletConnectUri, .address]

        static let walletConnectDeepLink = EventType(rawValue: 1 << 0)
        static let walletConnectUri = EventType(rawValue: 1 << 1)
        static let address = EventType(rawValue: 1 << 2)
    }

    enum HandleError: Error {
        case noSuitableHandler
    }
}

extension EventHandler.HandleError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noSuitableHandler: return "alert.cant_recognize".localized
        }
    }
}
