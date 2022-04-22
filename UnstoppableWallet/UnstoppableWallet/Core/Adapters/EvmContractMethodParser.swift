import BigInt
import EthereumKit

class EvmContractMethodParser {
    private var methods = [Data: String]()

    init() {
        addMethod(name: "Deposit", signature: "deposit(uint256)")
        addMethod(name: "TradeWithHintAndFee", signature: "tradeWithHintAndFee(address,uint256,address,address,uint256,uint256,address,uint256,bytes)")

        addMethod(name: "Farm Deposit", methodId: "0xe2bbb158")
        addMethod(name: "Farm Withdrawal", methodId: "0x441a3e70")
        addMethod(name: "Pool Deposit", methodId: "0xf305d719")
        addMethod(name: "Pool Withdrawal", methodId: "0xded9382a")
        addMethod(name: "Stake", methodId: "0xa59f3e0c")
        addMethod(name: "Unstake", methodId: "0x67dfd4c9")
        addMethod(name: "Swap", methodId: "0x5ae401dc") // Uniswap v3
    }

    private func addMethod(name: String, signature: String) {
        methods[ContractMethodHelper.methodId(signature: signature)] = name
    }

    private func addMethod(name: String, methodId: String) {
        guard let methodId = Data(hex: methodId) else {
            return
        }

        methods[methodId] = name
    }

}

extension EvmContractMethodParser {

    func parse(input: Data) -> String? {
        let methodId = Data(input.prefix(4))
        return methods[methodId]
    }

}
