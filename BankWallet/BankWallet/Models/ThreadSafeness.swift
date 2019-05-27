import Foundation

public class SynchronizedDictionary<KeyType: Hashable, ValueType> {
    private var dictionary: [KeyType: ValueType] = [:]
    private let accessQueue = DispatchQueue(label: "SynchronizedDictionaryAccess", attributes: .concurrent)

    func removeValue(forKey key: KeyType) {
        self.accessQueue.async(flags:.barrier) {
            self.dictionary.removeValue(forKey: key)
        }
    }

    subscript(key: KeyType) -> ValueType? {
        set {
            self.accessQueue.async(flags:.barrier) {
                self.dictionary[key] = newValue
            }
        }
        get {
            var element: ValueType!
            self.accessQueue.sync(flags: .barrier) {
                element = dictionary[key]
            }
            return element
        }
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