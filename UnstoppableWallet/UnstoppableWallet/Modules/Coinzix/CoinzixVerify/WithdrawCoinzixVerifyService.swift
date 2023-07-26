class WithdrawCoinzixVerifyService: ICoinzixVerifyService {
    private let orderId: Int
    private let provider: CoinzixCexProvider

    init(orderId: Int, provider: CoinzixCexProvider) {
        self.orderId = orderId
        self.provider = provider
    }

    func verify(emailCode: String?, googleCode: String?) async throws {
        try await provider.confirmWithdraw(id: orderId, emailPin: emailCode, googlePin: googleCode)
    }

    func resendPin() async throws {
        try await provider.sendWithdrawPin(id: orderId)
    }

}
