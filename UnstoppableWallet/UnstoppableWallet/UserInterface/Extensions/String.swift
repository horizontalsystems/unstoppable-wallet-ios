extension String {

    func stripping(prefix: String) -> String {
        if hasPrefix(prefix) {
            return String(dropFirst(prefix.count))
        }

        return self
    }

    var shortenedAddress: String {
        let prefixCount = hasPrefix("0x") ? 7 : 5
        return String(prefix(prefixCount)) + "..." + String(suffix(5))
    }

}
