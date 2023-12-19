enum FeeRateState {
    static let zero: FeeRateState = .value(0)

    case loading
    case value(Int)
    case error(Error)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var isValid: Bool {
        if case .value = self {
            return true
        }
        return false
    }

    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}
