//import XCTest
//import Quick
//import Nimble
//import Cuckoo
//@testable import Unstoppable_Dev_T
//
//class WordsValidatorTests: QuickSpec {
//
//    override func spec() {
//        let words = ["bmw", "audi", "toyota", "mazda"]
//        let validator = WordsValidator()
//
//        describe("not equal indexes and words count") {
//            let confirmationWords = ["bmw"]
//
//            it("throws invalidConfirmation error") {
//                expect {
//                    try validator.validate(words: words, confirmationIndexes: [1, 2], confirmationWords: confirmationWords)
//                }.to(throwError(WordsValidator.ValidationError.invalidConfirmation))
//            }
//        }
//        describe("empty words") {
//            context("without whitespaces") {
//                let confirmationWords = ["bmw", ""]
//
//                it("throws emptyWords error") {
//                    expect { try validator.validate(words: words, confirmationIndexes: [1, 2], confirmationWords: confirmationWords) }.to(throwError(WordsValidator.ValidationError.emptyWords))
//                }
//            }
//
//            context("with whitespaces") {
//                let confirmationWords = ["bmw", "  "]
//
//                it("throws emptyWords error") {
//                    expect { try validator.validate(words: words, confirmationIndexes: [1, 2], confirmationWords: confirmationWords) }.to(throwError(WordsValidator.ValidationError.emptyWords))
//                }
//            }
//        }
//
//        describe("invalid words") {
//            context("invalid word") {
//                let confirmationWords = ["renault", "audi"]
//
//                it("throws invalidConfirmation error") {
//                    expect { try validator.validate(words: words, confirmationIndexes: [1, 2], confirmationWords: confirmationWords) }.to(throwError(WordsValidator.ValidationError.invalidConfirmation))
//                }
//            }
//
//            context("invalid order") {
//                let confirmationWords = ["audi", "bmw"]
//
//                it("throws invalidConfirmation error") {
//                    expect { try validator.validate(words: words, confirmationIndexes: [1, 2], confirmationWords: confirmationWords) }.to(throwError(WordsValidator.ValidationError.invalidConfirmation))
//                }
//            }
//        }
//
//        describe("valid words") {
//            let confirmationWords = ["bmw", "audi"]
//
//            it("does not throw any errors") {
//                expect { try validator.validate(words: words, confirmationIndexes: [1, 2], confirmationWords: confirmationWords) }.notTo(throwError())
//            }
//        }
//
//    }
//
//}
//
