protocol IWCNVerifier: AnyObject {
    func handles(_ context: WCNVerificationContext) -> Bool
    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict
}

class WCNVerifierRegistry {
    private var verifiers = [IWCNVerifier]()

    func register(_ verifier: IWCNVerifier) {
        verifiers.append(verifier)
    }

    func verify(_ context: WCNVerificationContext) -> WCNVerificationVerdict {
        let verdicts = verifiers
            .filter { $0.handles(context) }
            .map { $0.verify(context) }

        return WCNVerificationVerdict.worst(verdicts)
    }
}
