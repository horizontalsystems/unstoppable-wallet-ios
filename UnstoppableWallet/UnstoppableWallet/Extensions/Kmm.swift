import Combine
import TonKitKmm

typealias OnEach<Output> = (Output) -> Void
typealias OnCompletion<Failure> = (Failure?) -> Void

typealias OnCollect<Output, Failure> = (@escaping OnEach<Output>, @escaping OnCompletion<Failure>) -> TonKitKmm.Cancellable

/**
 Creates a `Publisher` that collects output from a flow wrapper function emitting values from an underlying
 instance of `Flow<T>`.
 */
func collect<Output, Failure>(_ onCollect: @escaping OnCollect<Output, Failure>) -> Publishers.Flow<Output, Failure> {
    Publishers.Flow(onCollect: onCollect)
}

class SharedCancellableSubscription: Subscription {
    private var isCancelled: Bool = false

    var cancellable: TonKitKmm.Cancellable? {
        didSet {
            if isCancelled {
                cancellable?.cancel()
            }
        }
    }

    func request(_: Subscribers.Demand) {
        // Not supported
    }

    func cancel() {
        isCancelled = true
        cancellable?.cancel()
    }
}

extension Publishers {
    class Flow<Output, Failure: Error>: Publisher {
        private let onCollect: OnCollect<Output, Failure>

        init(onCollect: @escaping OnCollect<Output, Failure>) {
            self.onCollect = onCollect
        }

        func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
            let subscription = SharedCancellableSubscription()
            subscriber.receive(subscription: subscription)

            let cancellable = onCollect({ input in _ = subscriber.receive(input) }) { failure in
                if let failure {
                    subscriber.receive(completion: .failure(failure))
                } else {
                    subscriber.receive(completion: .finished)
                }
            }

            subscription.cancellable = cancellable
        }
    }
}

extension KotlinThrowable: Error {}

enum PublisherFailures {
    /**
     The action to invoke when a failure is dropped as the result of a `Publisher` returned by
     `Publisher.completeOnFailure()`.
     */
    static var willCompleteOnFailure: (Error, Callsite) -> Void = { error, callsite in
        //        if error.isKotlinCancellation {
        //            return
        //        }

        print("[ERROR] A publisher failed and was completed due to a call to `completeOnFailure()` \(callsite): \(error)")
    }
}

struct Callsite: CustomStringConvertible {
    let file: String
    let fileID: String
    let filePath: String
    let line: Int
    let column: Int
    let function: String
    let dsoHandle: UnsafeRawPointer

    var description: String {
        "in \(function) at \(filePath)#\(line):\(column)"
    }
}

extension Publisher {
    /**
     Ignores errors in the upstream publisher, emitting an empty sequence instead, and otherwise republishes all received input.
     You can hook into these failures by assigning a function to `PublisherHooks.willCompleteOnFailure`.
     */
    func completeOnFailure(file: String = #file, fileID: String = #fileID, filePath: String = #filePath, line: Int = #line, column: Int = #column, function: String = #function, dsoHandle: UnsafeRawPointer = #dsohandle) -> Publishers.Catch<Self, Empty<Output, Never>> {
        `catch` { error in
            let callsite = Callsite(file: file, fileID: fileID, filePath: filePath, line: line, column: column, function: function, dsoHandle: dsoHandle)
            PublisherFailures.willCompleteOnFailure(error, callsite)
            return Empty(completeImmediately: true)
        }
    }
}

extension Data {
    func toKotlinByteArray() -> KotlinByteArray {
        let swiftByteArray = [UInt8](self)
        return swiftByteArray
            .map(Int8.init(bitPattern:))
            .enumerated()
            .reduce(into: KotlinByteArray(size: Int32(swiftByteArray.count))) { result, row in
                result.set(index: Int32(row.offset), value: row.element)
            }
    }
}
