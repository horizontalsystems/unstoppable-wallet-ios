import XCTest
import Quick
import Nimble
import Cuckoo
@testable import Bank_Dev_T

class WordsValidatorTests: QuickSpec {

    override func spec() {
        let validator = WordsValidator(words: ["bmw", "audi", "toyota", "mazda"])

        describe("empty words") {
            context("without whitespaces") {
                let confirmationWords = [1: "bmw", 2: ""]

                it("throws emptyWords error") {
                    expect { try validator.validate(confirmationWords: confirmationWords) }.to(throwError(WordsValidator.ValidationError.emptyWords))
                }
            }

            context("with whitespaces") {
                let confirmationWords = [1: "bmw", 2: "  "]

                it("throws emptyWords error") {
                    expect { try validator.validate(confirmationWords: confirmationWords) }.to(throwError(WordsValidator.ValidationError.emptyWords))
                }
            }
        }

        describe("invalid words") {
            context("invalid word") {
                let confirmationWords = [1: "renault", 2: "audi"]

                it("throws invalidConfirmation error") {
                    expect { try validator.validate(confirmationWords: confirmationWords) }.to(throwError(WordsValidator.ValidationError.invalidConfirmation))
                }
            }

            context("invalid order") {
                let confirmationWords = [1: "audi", 2: "bmw"]

                it("throws invalidConfirmation error") {
                    expect { try validator.validate(confirmationWords: confirmationWords) }.to(throwError(WordsValidator.ValidationError.invalidConfirmation))
                }
            }
        }

        describe("valid words") {
            let confirmationWords = [1: "bmw", 2: "audi"]

            it("does not throw any errors") {
                expect { try validator.validate(confirmationWords: confirmationWords) }.notTo(throwError())
            }
        }

    }

}

