extension Dictionary {
    mutating func appendNotNil(key: Key, _ value: Value?) {
        if let value {
            self[key] = value
        }
    }
}
