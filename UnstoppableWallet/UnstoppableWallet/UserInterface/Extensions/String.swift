extension String {
    func stripping(prefix: String?) -> String {
        if let prefix, hasPrefix(prefix) {
            return String(dropFirst(prefix.count))
        }

        return self
    }

    var shortened: String {
        let excludedPrefixes = ["0x", "bc", "bnb", "ltc", "bitcoincash:", "ecash:"]

        var extraPrefix = 0

        for excludedPrefix in excludedPrefixes {
            if hasPrefix(excludedPrefix) {
                extraPrefix = excludedPrefix.count
                break
            }
        }

        return String(prefix(extraPrefix + 4)) + "..." + String(suffix(4))
    }
}

extension String: Identifiable {
    public var id: String {
        self
    }
}
