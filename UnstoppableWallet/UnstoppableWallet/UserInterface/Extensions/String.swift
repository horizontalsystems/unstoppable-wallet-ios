extension String {

    func stripping(prefix: String) -> String {
        if hasPrefix(prefix) {
            return String(dropFirst(prefix.count))
        }

        return self
    }

}
