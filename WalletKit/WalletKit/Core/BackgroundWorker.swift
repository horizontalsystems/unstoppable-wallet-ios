import Foundation

class BackgroundWorker: NSObject {

    private var thread: Thread!
    private var block: (() -> Void)?
    private let sync: Bool

    init(sync: Bool) {
        self.sync = sync
    }

    @objc internal func runBlock() {
        block?()
    }

    internal func start(block: @escaping () -> Void) {
        if sync {
            block()
            return
        }

        self.block = block

        let threadName = String(describing: self).components(separatedBy: .punctuationCharacters)[1]

        thread = Thread { [weak self] in
            while (self != nil && !self!.thread.isCancelled) {
                RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date.distantFuture)
            }
            Thread.exit()
        }
        thread.name = "\(threadName)-\(UUID().uuidString)"
        thread.start()

        perform(#selector(runBlock), on: thread, with: nil, waitUntilDone: false, modes: [RunLoopMode.defaultRunLoopMode.rawValue])
    }

    public func stop() {
        thread.cancel()
    }

}
