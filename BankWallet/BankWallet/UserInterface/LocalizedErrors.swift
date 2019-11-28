import Foundation
import BitcoinCore
import BinanceChainKit
import FeeRateKit
import EosKit
import Erc20Kit
import EthereumKit
import HSHDWalletKit
import Hodler

extension WordsValidator.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyWords:
            return "words_validator.empty_words".localized
        case .invalidConfirmation:
            return "words_validator.invalid_confirmation".localized
        }
    }
}

extension Mnemonic.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidWordsCount, .invalidWords:
            return "restore.validation_failed".localized
        }
    }
}

extension AccountCreator.CreateError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .eosNotSupported:
            return "error.cant_create_eos".localized
        }
    }
}

extension EosKit.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidPrivateKey:
            return "error.invalid_eos_key".localized
        }
    }
}

extension SendTransactionError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noFee: return "alert.no_fee".localized
        }
    }
}

extension EosAdapter.ValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidAccount: return "error.invalid_eos_account".localized
        }
    }
}

extension EosBackendError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .selfTransfer: return "error.send_eos.self_transfer".localized
        case .accountNotExist: return "error.send_eos.account_not_exist".localized
        case .insufficientRam: return "error.send_eos.insufficient_ram".localized
        case .unknown(let message): return "error.send_eos.unknown".localized(message)
        }
    }
}

extension ChartRateFactory.FactoryError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noChartPoints: return "chart.error.no_statistics".localized
        case .noPercentDelta: return "chart.error.no_percentDelta".localized
        }
    }
}

extension EthereumKit.ApiError: LocalizedError {

    public var errorDescription: String? {
        "error.send_ethereum.wrong_parameters".localized
    }

}