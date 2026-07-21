import Combine
import UIKit

class BackgroundTaskManager {
    private var activeSections = [UUID: UIBackgroundTaskIdentifier]()
    private let criticalCompletedSubject = PassthroughSubject<Void, Never>()

    private(set) var isCriticalActive = false

    var criticalCompletedPublisher: AnyPublisher<Void, Never> {
        criticalCompletedSubject.eraseToAnyPublisher()
    }

    // end() is awaited on both outcomes so callers observe a consistent state on return (no detached-Task races)
    func performCritical<T>(name: String, operation: () async throws -> T) async throws -> T {
        let token = await begin(name: name)

        do {
            let result = try await operation()
            await end(token: token)
            return result
        } catch {
            await end(token: token)
            throw error
        }
    }

    @MainActor
    private func begin(name: String) -> UUID {
        let token = UUID()

        var taskId: UIBackgroundTaskIdentifier = .invalid
        taskId = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            Task { await self?.end(token: token) }
        }

        // .invalid (system refused a window) still counts as an active section:
        // the deferred synchronizer stop must wait for the operation either way
        activeSections[token] = taskId
        isCriticalActive = true

        return token
    }

    @MainActor
    private func end(token: UUID) {
        guard let taskId = activeSections.removeValue(forKey: token) else { // already ended by the expiration handler
            return
        }

        if taskId != .invalid {
            UIApplication.shared.endBackgroundTask(taskId)
        }

        if activeSections.isEmpty {
            isCriticalActive = false
            criticalCompletedSubject.send()
        }
    }
}
