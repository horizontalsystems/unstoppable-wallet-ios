import Foundation

enum BroadcastGuard {
    /// The build flag, not anything at run time, decides whether a send is refused.
    static func check() throws {
        if AppEnvironment.isE2E {
            throw BroadcastDisabledError()
        }
    }
}

struct BroadcastDisabledError: LocalizedError {
    /// A literal on purpose: it shows only in the E2E build and matches Android's message.
    var errorDescription: String? {
        "Broadcasting is disabled in E2E builds"
    }
}
