enum EosBackendError: Error {
case selfTransfer
case accountNotExist
case insufficientRam
case unknown(message: String)
}