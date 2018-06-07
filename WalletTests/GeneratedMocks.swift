// MARK: - Mocks generated from file: Wallet/Modules/BackupWallet/BackupWalletModule.swift at 2018-06-07 06:15:44 +0000


import Cuckoo
@testable import Wallet

import BitcoinKit
import Darwin
import Foundation

class MockBackupWalletModule: BackupWalletModule, Cuckoo.ClassMock {
    typealias MocksType = BackupWalletModule
    typealias Stubbing = __StubbingProxy_BackupWalletModule
    typealias Verification = __VerificationProxy_BackupWalletModule
    let cuckoo_manager = Cuckoo.MockManager(hasParent: true)

    

    

    

	struct __StubbingProxy_BackupWalletModule: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	}

	struct __VerificationProxy_BackupWalletModule: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	}

}

 class BackupWalletModuleStub: BackupWalletModule {
    

    

    
}


class MockBackupWalletViewDelegate: BackupWalletViewDelegate, Cuckoo.ProtocolMock {
    typealias MocksType = BackupWalletViewDelegate
    typealias Stubbing = __StubbingProxy_BackupWalletViewDelegate
    typealias Verification = __VerificationProxy_BackupWalletViewDelegate
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "cancelDidTap", "returnSignature": "", "fullyQualifiedName": "cancelDidTap()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func cancelDidTap()  {
        
            return cuckoo_manager.call("cancelDidTap()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "showWordsDidTap", "returnSignature": "", "fullyQualifiedName": "showWordsDidTap()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func showWordsDidTap()  {
        
            return cuckoo_manager.call("showWordsDidTap()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "hideWordsDidTap", "returnSignature": "", "fullyQualifiedName": "hideWordsDidTap()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func hideWordsDidTap()  {
        
            return cuckoo_manager.call("hideWordsDidTap()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "showConfirmationDidTap", "returnSignature": "", "fullyQualifiedName": "showConfirmationDidTap()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func showConfirmationDidTap()  {
        
            return cuckoo_manager.call("showConfirmationDidTap()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "hideConfirmationDidTap", "returnSignature": "", "fullyQualifiedName": "hideConfirmationDidTap()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func hideConfirmationDidTap()  {
        
            return cuckoo_manager.call("hideConfirmationDidTap()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "validateDidTap", "returnSignature": "", "fullyQualifiedName": "validateDidTap(confirmationWords: [Int: String])", "parameterSignature": "confirmationWords: [Int: String]", "parameterSignatureWithoutNames": "confirmationWords: [Int: String]", "inputTypes": "[Int: String]", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "confirmationWords", "call": "confirmationWords: confirmationWords", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("confirmationWords"), name: "confirmationWords", type: "[Int: String]", range: CountableRange(834..<866), nameRange: CountableRange(834..<851))], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func validateDidTap(confirmationWords: [Int: String])  {
        
            return cuckoo_manager.call("validateDidTap(confirmationWords: [Int: String])",
                parameters: (confirmationWords),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_BackupWalletViewDelegate: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func cancelDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewDelegate.self, method: "cancelDidTap()", parameterMatchers: matchers))
	    }
	    
	    func showWordsDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewDelegate.self, method: "showWordsDidTap()", parameterMatchers: matchers))
	    }
	    
	    func hideWordsDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewDelegate.self, method: "hideWordsDidTap()", parameterMatchers: matchers))
	    }
	    
	    func showConfirmationDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewDelegate.self, method: "showConfirmationDidTap()", parameterMatchers: matchers))
	    }
	    
	    func hideConfirmationDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewDelegate.self, method: "hideConfirmationDidTap()", parameterMatchers: matchers))
	    }
	    
	    func validateDidTap<M1: Cuckoo.Matchable>(confirmationWords: M1) -> Cuckoo.ProtocolStubNoReturnFunction<([Int: String])> where M1.MatchedType == [Int: String] {
	        let matchers: [Cuckoo.ParameterMatcher<([Int: String])>] = [wrap(matchable: confirmationWords) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewDelegate.self, method: "validateDidTap(confirmationWords: [Int: String])", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_BackupWalletViewDelegate: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func cancelDidTap() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("cancelDidTap()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func showWordsDidTap() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showWordsDidTap()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func hideWordsDidTap() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("hideWordsDidTap()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func showConfirmationDidTap() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showConfirmationDidTap()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func hideConfirmationDidTap() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("hideConfirmationDidTap()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func validateDidTap<M1: Cuckoo.Matchable>(confirmationWords: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [Int: String] {
	        let matchers: [Cuckoo.ParameterMatcher<([Int: String])>] = [wrap(matchable: confirmationWords) { $0 }]
	        return cuckoo_manager.verify("validateDidTap(confirmationWords: [Int: String])", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class BackupWalletViewDelegateStub: BackupWalletViewDelegate {
    

    

    
     func cancelDidTap()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func showWordsDidTap()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func hideWordsDidTap()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func showConfirmationDidTap()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func hideConfirmationDidTap()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func validateDidTap(confirmationWords: [Int: String])  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockBackupWalletViewProtocol: BackupWalletViewProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = BackupWalletViewProtocol
    typealias Stubbing = __StubbingProxy_BackupWalletViewProtocol
    typealias Verification = __VerificationProxy_BackupWalletViewProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "show", "returnSignature": "", "fullyQualifiedName": "show(words: [String])", "parameterSignature": "words: [String]", "parameterSignatureWithoutNames": "words: [String]", "inputTypes": "[String]", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "words", "call": "words: words", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("words"), name: "words", type: "[String]", range: CountableRange(928..<943), nameRange: CountableRange(928..<933))], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func show(words: [String])  {
        
            return cuckoo_manager.call("show(words: [String])",
                parameters: (words),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "showConfirmation", "returnSignature": "", "fullyQualifiedName": "showConfirmation(withIndexes: [Int])", "parameterSignature": "withIndexes indexes: [Int]", "parameterSignatureWithoutNames": "indexes: [Int]", "inputTypes": "[Int]", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "indexes", "call": "withIndexes: indexes", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("withIndexes"), name: "indexes", type: "[Int]", range: CountableRange(971..<997), nameRange: CountableRange(971..<982))], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func showConfirmation(withIndexes indexes: [Int])  {
        
            return cuckoo_manager.call("showConfirmation(withIndexes: [Int])",
                parameters: (indexes),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "hideWords", "returnSignature": "", "fullyQualifiedName": "hideWords()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func hideWords()  {
        
            return cuckoo_manager.call("hideWords()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "hideConfirmation", "returnSignature": "", "fullyQualifiedName": "hideConfirmation()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func hideConfirmation()  {
        
            return cuckoo_manager.call("hideConfirmation()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "showValidationFailure", "returnSignature": "", "fullyQualifiedName": "showValidationFailure()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func showValidationFailure()  {
        
            return cuckoo_manager.call("showValidationFailure()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_BackupWalletViewProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func show<M1: Cuckoo.Matchable>(words: M1) -> Cuckoo.ProtocolStubNoReturnFunction<([String])> where M1.MatchedType == [String] {
	        let matchers: [Cuckoo.ParameterMatcher<([String])>] = [wrap(matchable: words) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewProtocol.self, method: "show(words: [String])", parameterMatchers: matchers))
	    }
	    
	    func showConfirmation<M1: Cuckoo.Matchable>(withIndexes indexes: M1) -> Cuckoo.ProtocolStubNoReturnFunction<([Int])> where M1.MatchedType == [Int] {
	        let matchers: [Cuckoo.ParameterMatcher<([Int])>] = [wrap(matchable: indexes) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewProtocol.self, method: "showConfirmation(withIndexes: [Int])", parameterMatchers: matchers))
	    }
	    
	    func hideWords() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewProtocol.self, method: "hideWords()", parameterMatchers: matchers))
	    }
	    
	    func hideConfirmation() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewProtocol.self, method: "hideConfirmation()", parameterMatchers: matchers))
	    }
	    
	    func showValidationFailure() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletViewProtocol.self, method: "showValidationFailure()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_BackupWalletViewProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func show<M1: Cuckoo.Matchable>(words: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [String] {
	        let matchers: [Cuckoo.ParameterMatcher<([String])>] = [wrap(matchable: words) { $0 }]
	        return cuckoo_manager.verify("show(words: [String])", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func showConfirmation<M1: Cuckoo.Matchable>(withIndexes indexes: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [Int] {
	        let matchers: [Cuckoo.ParameterMatcher<([Int])>] = [wrap(matchable: indexes) { $0 }]
	        return cuckoo_manager.verify("showConfirmation(withIndexes: [Int])", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func hideWords() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("hideWords()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func hideConfirmation() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("hideConfirmation()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func showValidationFailure() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showValidationFailure()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class BackupWalletViewProtocolStub: BackupWalletViewProtocol {
    

    

    
     func show(words: [String])  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func showConfirmation(withIndexes indexes: [Int])  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func hideWords()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func hideConfirmation()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func showValidationFailure()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockBackupWalletPresenterDelegate: BackupWalletPresenterDelegate, Cuckoo.ProtocolMock {
    typealias MocksType = BackupWalletPresenterDelegate
    typealias Stubbing = __StubbingProxy_BackupWalletPresenterDelegate
    typealias Verification = __VerificationProxy_BackupWalletPresenterDelegate
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "fetchWords", "returnSignature": "", "fullyQualifiedName": "fetchWords()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func fetchWords()  {
        
            return cuckoo_manager.call("fetchWords()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "fetchConfirmationIndexes", "returnSignature": "", "fullyQualifiedName": "fetchConfirmationIndexes()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func fetchConfirmationIndexes()  {
        
            return cuckoo_manager.call("fetchConfirmationIndexes()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "validate", "returnSignature": "", "fullyQualifiedName": "validate(confirmationWords: [Int: String])", "parameterSignature": "confirmationWords: [Int: String]", "parameterSignatureWithoutNames": "confirmationWords: [Int: String]", "inputTypes": "[Int: String]", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "confirmationWords", "call": "confirmationWords: confirmationWords", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("confirmationWords"), name: "confirmationWords", type: "[Int: String]", range: CountableRange(1201..<1233), nameRange: CountableRange(1201..<1218))], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func validate(confirmationWords: [Int: String])  {
        
            return cuckoo_manager.call("validate(confirmationWords: [Int: String])",
                parameters: (confirmationWords),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_BackupWalletPresenterDelegate: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func fetchWords() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletPresenterDelegate.self, method: "fetchWords()", parameterMatchers: matchers))
	    }
	    
	    func fetchConfirmationIndexes() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletPresenterDelegate.self, method: "fetchConfirmationIndexes()", parameterMatchers: matchers))
	    }
	    
	    func validate<M1: Cuckoo.Matchable>(confirmationWords: M1) -> Cuckoo.ProtocolStubNoReturnFunction<([Int: String])> where M1.MatchedType == [Int: String] {
	        let matchers: [Cuckoo.ParameterMatcher<([Int: String])>] = [wrap(matchable: confirmationWords) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletPresenterDelegate.self, method: "validate(confirmationWords: [Int: String])", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_BackupWalletPresenterDelegate: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func fetchWords() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("fetchWords()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func fetchConfirmationIndexes() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("fetchConfirmationIndexes()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func validate<M1: Cuckoo.Matchable>(confirmationWords: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [Int: String] {
	        let matchers: [Cuckoo.ParameterMatcher<([Int: String])>] = [wrap(matchable: confirmationWords) { $0 }]
	        return cuckoo_manager.verify("validate(confirmationWords: [Int: String])", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class BackupWalletPresenterDelegateStub: BackupWalletPresenterDelegate {
    

    

    
     func fetchWords()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func fetchConfirmationIndexes()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func validate(confirmationWords: [Int: String])  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockBackupWalletPresenterProtocol: BackupWalletPresenterProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = BackupWalletPresenterProtocol
    typealias Stubbing = __StubbingProxy_BackupWalletPresenterProtocol
    typealias Verification = __VerificationProxy_BackupWalletPresenterProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "didFetch", "returnSignature": "", "fullyQualifiedName": "didFetch(words: [String])", "parameterSignature": "words: [String]", "parameterSignatureWithoutNames": "words: [String]", "inputTypes": "[String]", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "words", "call": "words: words", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("words"), name: "words", type: "[String]", range: CountableRange(1304..<1319), nameRange: CountableRange(1304..<1309))], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func didFetch(words: [String])  {
        
            return cuckoo_manager.call("didFetch(words: [String])",
                parameters: (words),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "didFetch", "returnSignature": "", "fullyQualifiedName": "didFetch(confirmationIndexes: [Int])", "parameterSignature": "confirmationIndexes indexes: [Int]", "parameterSignatureWithoutNames": "indexes: [Int]", "inputTypes": "[Int]", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "indexes", "call": "confirmationIndexes: indexes", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("confirmationIndexes"), name: "indexes", type: "[Int]", range: CountableRange(1339..<1373), nameRange: CountableRange(1339..<1358))], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func didFetch(confirmationIndexes indexes: [Int])  {
        
            return cuckoo_manager.call("didFetch(confirmationIndexes: [Int])",
                parameters: (indexes),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "didValidateSuccess", "returnSignature": "", "fullyQualifiedName": "didValidateSuccess()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func didValidateSuccess()  {
        
            return cuckoo_manager.call("didValidateSuccess()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "didValidateFailure", "returnSignature": "", "fullyQualifiedName": "didValidateFailure()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func didValidateFailure()  {
        
            return cuckoo_manager.call("didValidateFailure()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_BackupWalletPresenterProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func didFetch<M1: Cuckoo.Matchable>(words: M1) -> Cuckoo.ProtocolStubNoReturnFunction<([String])> where M1.MatchedType == [String] {
	        let matchers: [Cuckoo.ParameterMatcher<([String])>] = [wrap(matchable: words) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletPresenterProtocol.self, method: "didFetch(words: [String])", parameterMatchers: matchers))
	    }
	    
	    func didFetch<M1: Cuckoo.Matchable>(confirmationIndexes indexes: M1) -> Cuckoo.ProtocolStubNoReturnFunction<([Int])> where M1.MatchedType == [Int] {
	        let matchers: [Cuckoo.ParameterMatcher<([Int])>] = [wrap(matchable: indexes) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletPresenterProtocol.self, method: "didFetch(confirmationIndexes: [Int])", parameterMatchers: matchers))
	    }
	    
	    func didValidateSuccess() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletPresenterProtocol.self, method: "didValidateSuccess()", parameterMatchers: matchers))
	    }
	    
	    func didValidateFailure() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletPresenterProtocol.self, method: "didValidateFailure()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_BackupWalletPresenterProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func didFetch<M1: Cuckoo.Matchable>(words: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [String] {
	        let matchers: [Cuckoo.ParameterMatcher<([String])>] = [wrap(matchable: words) { $0 }]
	        return cuckoo_manager.verify("didFetch(words: [String])", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func didFetch<M1: Cuckoo.Matchable>(confirmationIndexes indexes: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == [Int] {
	        let matchers: [Cuckoo.ParameterMatcher<([Int])>] = [wrap(matchable: indexes) { $0 }]
	        return cuckoo_manager.verify("didFetch(confirmationIndexes: [Int])", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func didValidateSuccess() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("didValidateSuccess()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func didValidateFailure() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("didValidateFailure()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class BackupWalletPresenterProtocolStub: BackupWalletPresenterProtocol {
    

    

    
     func didFetch(words: [String])  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func didFetch(confirmationIndexes indexes: [Int])  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func didValidateSuccess()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func didValidateFailure()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockBackupWalletRouterProtocol: BackupWalletRouterProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = BackupWalletRouterProtocol
    typealias Stubbing = __StubbingProxy_BackupWalletRouterProtocol
    typealias Verification = __VerificationProxy_BackupWalletRouterProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "close", "returnSignature": "", "fullyQualifiedName": "close()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func close()  {
        
            return cuckoo_manager.call("close()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_BackupWalletRouterProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func close() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletRouterProtocol.self, method: "close()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_BackupWalletRouterProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func close() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("close()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class BackupWalletRouterProtocolStub: BackupWalletRouterProtocol {
    

    

    
     func close()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockBackupWalletWordsProviderProtocol: BackupWalletWordsProviderProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = BackupWalletWordsProviderProtocol
    typealias Stubbing = __StubbingProxy_BackupWalletWordsProviderProtocol
    typealias Verification = __VerificationProxy_BackupWalletWordsProviderProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "getWords", "returnSignature": " -> [String]", "fullyQualifiedName": "getWords() -> [String]", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "[String]", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubFunction"]
     func getWords()  -> [String] {
        
            return cuckoo_manager.call("getWords() -> [String]",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_BackupWalletWordsProviderProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func getWords() -> Cuckoo.ProtocolStubFunction<(), [String]> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletWordsProviderProtocol.self, method: "getWords() -> [String]", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_BackupWalletWordsProviderProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func getWords() -> Cuckoo.__DoNotUse<[String]> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("getWords() -> [String]", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class BackupWalletWordsProviderProtocolStub: BackupWalletWordsProviderProtocol {
    

    

    
     func getWords()  -> [String] {
        return DefaultValueRegistry.defaultValue(for: [String].self)
    }
    
}


class MockBackupWalletRandomIndexesProviderProtocol: BackupWalletRandomIndexesProviderProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = BackupWalletRandomIndexesProviderProtocol
    typealias Stubbing = __StubbingProxy_BackupWalletRandomIndexesProviderProtocol
    typealias Verification = __VerificationProxy_BackupWalletRandomIndexesProviderProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "getRandomIndexes", "returnSignature": " -> [Int]", "fullyQualifiedName": "getRandomIndexes(count: Int) -> [Int]", "parameterSignature": "count: Int", "parameterSignatureWithoutNames": "count: Int", "inputTypes": "Int", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "count", "call": "count: count", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("count"), name: "count", type: "Int", range: CountableRange(1655..<1665), nameRange: CountableRange(1655..<1660))], "returnType": "[Int]", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubFunction"]
     func getRandomIndexes(count: Int)  -> [Int] {
        
            return cuckoo_manager.call("getRandomIndexes(count: Int) -> [Int]",
                parameters: (count),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_BackupWalletRandomIndexesProviderProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func getRandomIndexes<M1: Cuckoo.Matchable>(count: M1) -> Cuckoo.ProtocolStubFunction<(Int), [Int]> where M1.MatchedType == Int {
	        let matchers: [Cuckoo.ParameterMatcher<(Int)>] = [wrap(matchable: count) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockBackupWalletRandomIndexesProviderProtocol.self, method: "getRandomIndexes(count: Int) -> [Int]", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_BackupWalletRandomIndexesProviderProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func getRandomIndexes<M1: Cuckoo.Matchable>(count: M1) -> Cuckoo.__DoNotUse<[Int]> where M1.MatchedType == Int {
	        let matchers: [Cuckoo.ParameterMatcher<(Int)>] = [wrap(matchable: count) { $0 }]
	        return cuckoo_manager.verify("getRandomIndexes(count: Int) -> [Int]", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class BackupWalletRandomIndexesProviderProtocolStub: BackupWalletRandomIndexesProviderProtocol {
    

    

    
     func getRandomIndexes(count: Int)  -> [Int] {
        return DefaultValueRegistry.defaultValue(for: [Int].self)
    }
    
}


class MockWalletManager: WalletManager, Cuckoo.ClassMock {
    typealias MocksType = WalletManager
    typealias Stubbing = __StubbingProxy_WalletManager
    typealias Verification = __VerificationProxy_WalletManager
    let cuckoo_manager = Cuckoo.MockManager(hasParent: true)

    

    

    
    // ["name": "getWords", "returnSignature": " -> [String]", "fullyQualifiedName": "getWords() -> [String]", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "[String]", "isOptional": false, "stubFunction": "Cuckoo.ClassStubFunction"]
     override func getWords()  -> [String] {
        
            return cuckoo_manager.call("getWords() -> [String]",
                parameters: (),
                superclassCall:
                    
                    super.getWords()
                    )
        
    }
    

	struct __StubbingProxy_WalletManager: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func getWords() -> Cuckoo.ClassStubFunction<(), [String]> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockWalletManager.self, method: "getWords() -> [String]", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_WalletManager: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func getWords() -> Cuckoo.__DoNotUse<[String]> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("getWords() -> [String]", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class WalletManagerStub: WalletManager {
    

    

    
     override func getWords()  -> [String] {
        return DefaultValueRegistry.defaultValue(for: [String].self)
    }
    
}


class MockRandomProvider: RandomProvider, Cuckoo.ClassMock {
    typealias MocksType = RandomProvider
    typealias Stubbing = __StubbingProxy_RandomProvider
    typealias Verification = __VerificationProxy_RandomProvider
    let cuckoo_manager = Cuckoo.MockManager(hasParent: true)

    

    

    
    // ["name": "getRandomIndexes", "returnSignature": " -> [Int]", "fullyQualifiedName": "getRandomIndexes(count: Int) -> [Int]", "parameterSignature": "count: Int", "parameterSignatureWithoutNames": "count: Int", "inputTypes": "Int", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "count", "call": "count: count", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("count"), name: "count", type: "Int", range: CountableRange(2043..<2053), nameRange: CountableRange(2043..<2048))], "returnType": "[Int]", "isOptional": false, "stubFunction": "Cuckoo.ClassStubFunction"]
     override func getRandomIndexes(count: Int)  -> [Int] {
        
            return cuckoo_manager.call("getRandomIndexes(count: Int) -> [Int]",
                parameters: (count),
                superclassCall:
                    
                    super.getRandomIndexes(count: count)
                    )
        
    }
    

	struct __StubbingProxy_RandomProvider: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func getRandomIndexes<M1: Cuckoo.Matchable>(count: M1) -> Cuckoo.ClassStubFunction<(Int), [Int]> where M1.MatchedType == Int {
	        let matchers: [Cuckoo.ParameterMatcher<(Int)>] = [wrap(matchable: count) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockRandomProvider.self, method: "getRandomIndexes(count: Int) -> [Int]", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_RandomProvider: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func getRandomIndexes<M1: Cuckoo.Matchable>(count: M1) -> Cuckoo.__DoNotUse<[Int]> where M1.MatchedType == Int {
	        let matchers: [Cuckoo.ParameterMatcher<(Int)>] = [wrap(matchable: count) { $0 }]
	        return cuckoo_manager.verify("getRandomIndexes(count: Int) -> [Int]", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class RandomProviderStub: RandomProvider {
    

    

    
     override func getRandomIndexes(count: Int)  -> [Int] {
        return DefaultValueRegistry.defaultValue(for: [Int].self)
    }
    
}


// MARK: - Mocks generated from file: Wallet/Modules/Guest/GuestModule.swift at 2018-06-07 06:15:44 +0000


import Cuckoo
@testable import Wallet

import Foundation

class MockGuestModule: GuestModule, Cuckoo.ClassMock {
    typealias MocksType = GuestModule
    typealias Stubbing = __StubbingProxy_GuestModule
    typealias Verification = __VerificationProxy_GuestModule
    let cuckoo_manager = Cuckoo.MockManager(hasParent: true)

    

    

    

	struct __StubbingProxy_GuestModule: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	}

	struct __VerificationProxy_GuestModule: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	}

}

 class GuestModuleStub: GuestModule {
    

    

    
}


class MockGuestViewDelegate: GuestViewDelegate, Cuckoo.ProtocolMock {
    typealias MocksType = GuestViewDelegate
    typealias Stubbing = __StubbingProxy_GuestViewDelegate
    typealias Verification = __VerificationProxy_GuestViewDelegate
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "createNewWalletDidTap", "returnSignature": "", "fullyQualifiedName": "createNewWalletDidTap()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func createNewWalletDidTap()  {
        
            return cuckoo_manager.call("createNewWalletDidTap()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "restoreWalletDidTap", "returnSignature": "", "fullyQualifiedName": "restoreWalletDidTap()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func restoreWalletDidTap()  {
        
            return cuckoo_manager.call("restoreWalletDidTap()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_GuestViewDelegate: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func createNewWalletDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestViewDelegate.self, method: "createNewWalletDidTap()", parameterMatchers: matchers))
	    }
	    
	    func restoreWalletDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestViewDelegate.self, method: "restoreWalletDidTap()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_GuestViewDelegate: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func createNewWalletDidTap() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("createNewWalletDidTap()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func restoreWalletDidTap() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("restoreWalletDidTap()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class GuestViewDelegateStub: GuestViewDelegate {
    

    

    
     func createNewWalletDidTap()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func restoreWalletDidTap()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockGuestRouterProtocol: GuestRouterProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = GuestRouterProtocol
    typealias Stubbing = __StubbingProxy_GuestRouterProtocol
    typealias Verification = __VerificationProxy_GuestRouterProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "showBackupWallet", "returnSignature": "", "fullyQualifiedName": "showBackupWallet()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func showBackupWallet()  {
        
            return cuckoo_manager.call("showBackupWallet()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "showRestoreWallet", "returnSignature": "", "fullyQualifiedName": "showRestoreWallet()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func showRestoreWallet()  {
        
            return cuckoo_manager.call("showRestoreWallet()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_GuestRouterProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func showBackupWallet() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestRouterProtocol.self, method: "showBackupWallet()", parameterMatchers: matchers))
	    }
	    
	    func showRestoreWallet() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestRouterProtocol.self, method: "showRestoreWallet()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_GuestRouterProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func showBackupWallet() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showBackupWallet()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func showRestoreWallet() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showRestoreWallet()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class GuestRouterProtocolStub: GuestRouterProtocol {
    

    

    
     func showBackupWallet()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func showRestoreWallet()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


// MARK: - Mocks generated from file: Wallet/Modules/RestoreWallet/RestoreWalletModule.swift at 2018-06-07 06:15:44 +0000


import Cuckoo
@testable import Wallet

import Foundation

class MockRestoreWalletModule: RestoreWalletModule, Cuckoo.ClassMock {
    typealias MocksType = RestoreWalletModule
    typealias Stubbing = __StubbingProxy_RestoreWalletModule
    typealias Verification = __VerificationProxy_RestoreWalletModule
    let cuckoo_manager = Cuckoo.MockManager(hasParent: true)

    

    

    

	struct __StubbingProxy_RestoreWalletModule: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	}

	struct __VerificationProxy_RestoreWalletModule: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	}

}

 class RestoreWalletModuleStub: RestoreWalletModule {
    

    

    
}


class MockRestoreWalletViewDelegate: RestoreWalletViewDelegate, Cuckoo.ProtocolMock {
    typealias MocksType = RestoreWalletViewDelegate
    typealias Stubbing = __StubbingProxy_RestoreWalletViewDelegate
    typealias Verification = __VerificationProxy_RestoreWalletViewDelegate
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "cancelDidTap", "returnSignature": "", "fullyQualifiedName": "cancelDidTap()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func cancelDidTap()  {
        
            return cuckoo_manager.call("cancelDidTap()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_RestoreWalletViewDelegate: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func cancelDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockRestoreWalletViewDelegate.self, method: "cancelDidTap()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_RestoreWalletViewDelegate: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func cancelDidTap() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("cancelDidTap()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class RestoreWalletViewDelegateStub: RestoreWalletViewDelegate {
    

    

    
     func cancelDidTap()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockRestoreWalletViewProtocol: RestoreWalletViewProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = RestoreWalletViewProtocol
    typealias Stubbing = __StubbingProxy_RestoreWalletViewProtocol
    typealias Verification = __VerificationProxy_RestoreWalletViewProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    

	struct __StubbingProxy_RestoreWalletViewProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	}

	struct __VerificationProxy_RestoreWalletViewProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	}

}

 class RestoreWalletViewProtocolStub: RestoreWalletViewProtocol {
    

    

    
}


class MockRestoreWalletPresenterDelegate: RestoreWalletPresenterDelegate, Cuckoo.ProtocolMock {
    typealias MocksType = RestoreWalletPresenterDelegate
    typealias Stubbing = __StubbingProxy_RestoreWalletPresenterDelegate
    typealias Verification = __VerificationProxy_RestoreWalletPresenterDelegate
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    

	struct __StubbingProxy_RestoreWalletPresenterDelegate: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	}

	struct __VerificationProxy_RestoreWalletPresenterDelegate: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	}

}

 class RestoreWalletPresenterDelegateStub: RestoreWalletPresenterDelegate {
    

    

    
}


class MockRestoreWalletPresenterProtocol: RestoreWalletPresenterProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = RestoreWalletPresenterProtocol
    typealias Stubbing = __StubbingProxy_RestoreWalletPresenterProtocol
    typealias Verification = __VerificationProxy_RestoreWalletPresenterProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    

	struct __StubbingProxy_RestoreWalletPresenterProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	}

	struct __VerificationProxy_RestoreWalletPresenterProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	}

}

 class RestoreWalletPresenterProtocolStub: RestoreWalletPresenterProtocol {
    

    

    
}


class MockRestoreWalletRouterProtocol: RestoreWalletRouterProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = RestoreWalletRouterProtocol
    typealias Stubbing = __StubbingProxy_RestoreWalletRouterProtocol
    typealias Verification = __VerificationProxy_RestoreWalletRouterProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "close", "returnSignature": "", "fullyQualifiedName": "close()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func close()  {
        
            return cuckoo_manager.call("close()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_RestoreWalletRouterProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func close() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockRestoreWalletRouterProtocol.self, method: "close()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_RestoreWalletRouterProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func close() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("close()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class RestoreWalletRouterProtocolStub: RestoreWalletRouterProtocol {
    

    

    
     func close()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}

