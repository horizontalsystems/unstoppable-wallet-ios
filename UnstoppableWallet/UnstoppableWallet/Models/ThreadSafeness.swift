import Foundation

class SynchronizedDictionary<KeyType: Hashable, ValueType> {
    private var dictionary: [KeyType: ValueType] = [:]
    private let queue: DispatchQueue

    init(queueLabel: String = "SynchronizedDictionaryAccess") {
        queue = DispatchQueue(label: "SynchronizedDictionaryAccess", attributes: .concurrent)
    }

    subscript(key: KeyType) -> ValueType? {
        set {
            queue.async(flags: .barrier) {
                self.dictionary[key] = newValue
            }
        }
        get {
            queue.sync {
                dictionary[key]
            }
        }
    }

    var rawDictionary: [KeyType: ValueType] {
        set {
            queue.async(flags: .barrier) {
                self.dictionary = newValue
            }
        }
        get {
            queue.sync {
                dictionary
            }
        }
    }

    var count: Int {
        var count = 0

        self.queue.sync {
            count = self.dictionary.count
        }

        return count
    }

    func removeValue(forKey key: KeyType) {
        queue.async(flags: .barrier) {
            self.dictionary.removeValue(forKey: key)
        }
    }

    func contains(where predicate: ((key: KeyType, value: ValueType)) throws -> Bool) rethrows -> Bool {
        var contains = false

        try self.queue.sync {
            contains = try self.dictionary.contains(where: predicate)
        }

        return contains
    }

    func min(by areInIncreasingOrder: ((key: KeyType, value: ValueType), (key: KeyType, value: ValueType)) throws -> Bool) rethrows -> (key: KeyType, value: ValueType)? {
        var min: (key: KeyType, value: ValueType)? = nil

        try self.queue.sync {
            min = try self.dictionary.min(by: areInIncreasingOrder)
        }

        return min
    }

}

public class SynchronizedArray<T> {
    private var array: [T] = []
    private let accessQueue = DispatchQueue(label: "SynchronizedArrayAccess", attributes: .concurrent)

    public func append(_ newElement: T) {

        self.accessQueue.async(flags:.barrier) {
            self.array.append(newElement)
        }
    }

    public func removeAtIndex(index: Int) {

        self.accessQueue.async(flags:.barrier) {
            self.array.remove(at: index)
        }
    }

    public var count: Int {
        var count = 0

        self.accessQueue.sync {
            count = self.array.count
        }

        return count
    }

    public func first() -> T? {
        var element: T?

        self.accessQueue.sync {
            if !self.array.isEmpty {
                element = self.array[0]
            }
        }

        return element
    }

    public subscript(index: Int) -> T {
        set {
            self.accessQueue.async(flags:.barrier) {
                self.array[index] = newValue
            }
        }
        get {
            var element: T!
            self.accessQueue.sync {
                element = self.array[index]
            }

            return element
        }
    }

    func forEach(_ body: (T) -> ()) {
        self.accessQueue.sync {
            array.forEach { value in
                body(value)
            }
        }
    }

    func filter(_ isIncluded: (T) -> Bool) -> [T] {
        return array.filter { value in isIncluded(value) }
    }

}
