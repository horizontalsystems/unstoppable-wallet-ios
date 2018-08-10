import Foundation

class ScriptBuilder {

    enum BuildError: Error { case wrongDataCount, unknownType }

    func lockingScript(type: ScriptType, params: [Data]) throws -> Data {
        guard params.count == 1 else {
            throw BuildError.wrongDataCount
        }

        switch type {
            case .p2pkh: return OpCode.p2pkhStart + OpCode.push(params[0]) + OpCode.p2pkhFinish
            case .p2pk: return OpCode.push(params[0]) + OpCode.p2pkFinish
            case .p2sh: return OpCode.p2shStart + OpCode.push(params[0]) + OpCode.p2shFinish
            default: throw BuildError.unknownType
        }
    }

    func unlockingScript(params: [Data]) -> Data {
        return params.reduce(Data()) { $0 + OpCode.push($1) }
    }

}
