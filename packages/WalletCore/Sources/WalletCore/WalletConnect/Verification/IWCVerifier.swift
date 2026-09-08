protocol IWCVerifier: AnyObject {
    func handles(_ context: WCVerificationContext) -> Bool
    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict
}

class WCVerifierRegistry {
    private var verifiers = [IWCVerifier]()

    func register(_ verifier: IWCVerifier) {
        verifiers.append(verifier)
    }

    func verify(_ context: WCVerificationContext) -> WCVerificationVerdict {
        let verdicts = verifiers
            .filter { $0.handles(context) }
            .map { $0.verify(context) }

        return WCVerificationVerdict.worst(verdicts)
    }
}
