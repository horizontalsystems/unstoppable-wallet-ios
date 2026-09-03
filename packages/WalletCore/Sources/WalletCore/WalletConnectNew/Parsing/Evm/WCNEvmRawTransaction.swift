// JSON shape of eth_sendTransaction / eth_signTransaction params[0]; `gasLimit` is the legacy alias of `gas`
struct WCNEvmRawTransaction: Codable {
    let from: String
    let to: String?
    let nonce: String?
    let gasPrice: String?
    let gas: String?
    let gasLimit: String?
    let maxPriorityFeePerGas: String?
    let maxFeePerGas: String?
    let value: String?
    let data: String?
}
