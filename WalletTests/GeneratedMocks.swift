// MARK: - Mocks generated from file: Wallet/Modules/CreateWallet/CreateWalletRouter.swift at 2018-06-05 09:37:00 +0000


import Cuckoo
@testable import Wallet

import BitcoinKit
import Foundation

class MockCreateWalletRouter: CreateWalletRouter, Cuckoo.ClassMock {
    typealias MocksType = CreateWalletRouter
    typealias Stubbing = __StubbingProxy_CreateWalletRouter
    typealias Verification = __VerificationProxy_CreateWalletRouter
    let cuckoo_manager = Cuckoo.MockManager(hasParent: true)

    

    

    

	struct __StubbingProxy_CreateWalletRouter: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	}

	struct __VerificationProxy_CreateWalletRouter: Cuckoo.VerificationProxy {
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

 class CreateWalletRouterStub: CreateWalletRouter {
    

    

    
}


class MockCreateWalletViewDelegate: CreateWalletViewDelegate, Cuckoo.ProtocolMock {
    typealias MocksType = CreateWalletViewDelegate
    typealias Stubbing = __StubbingProxy_CreateWalletViewDelegate
    typealias Verification = __VerificationProxy_CreateWalletViewDelegate
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "viewDidLoad", "returnSignature": "", "fullyQualifiedName": "viewDidLoad()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func viewDidLoad()  {
        
            return cuckoo_manager.call("viewDidLoad()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_CreateWalletViewDelegate: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func viewDidLoad() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockCreateWalletViewDelegate.self, method: "viewDidLoad()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_CreateWalletViewDelegate: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func viewDidLoad() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("viewDidLoad()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class CreateWalletViewDelegateStub: CreateWalletViewDelegate {
    

    

    
     func viewDidLoad()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockCreateWalletViewProtocol: CreateWalletViewProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = CreateWalletViewProtocol
    typealias Stubbing = __StubbingProxy_CreateWalletViewProtocol
    typealias Verification = __VerificationProxy_CreateWalletViewProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "show", "returnSignature": "", "fullyQualifiedName": "show(wordsString: String)", "parameterSignature": "wordsString: String", "parameterSignatureWithoutNames": "wordsString: String", "inputTypes": "String", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "wordsString", "call": "wordsString: wordsString", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("wordsString"), name: "wordsString", type: "String", range: CountableRange(554..<573), nameRange: CountableRange(554..<565))], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func show(wordsString: String)  {
        
            return cuckoo_manager.call("show(wordsString: String)",
                parameters: (wordsString),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_CreateWalletViewProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func show<M1: Cuckoo.Matchable>(wordsString: M1) -> Cuckoo.ProtocolStubNoReturnFunction<(String)> where M1.MatchedType == String {
	        let matchers: [Cuckoo.ParameterMatcher<(String)>] = [wrap(matchable: wordsString) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockCreateWalletViewProtocol.self, method: "show(wordsString: String)", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_CreateWalletViewProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func show<M1: Cuckoo.Matchable>(wordsString: M1) -> Cuckoo.__DoNotUse<Void> where M1.MatchedType == String {
	        let matchers: [Cuckoo.ParameterMatcher<(String)>] = [wrap(matchable: wordsString) { $0 }]
	        return cuckoo_manager.verify("show(wordsString: String)", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class CreateWalletViewProtocolStub: CreateWalletViewProtocol {
    

    

    
     func show(wordsString: String)  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockCreateWalletPresenterProtocol: CreateWalletPresenterProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = CreateWalletPresenterProtocol
    typealias Stubbing = __StubbingProxy_CreateWalletPresenterProtocol
    typealias Verification = __VerificationProxy_CreateWalletPresenterProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "show", "returnSignature": "", "fullyQualifiedName": "show(words: [String])", "parameterSignature": "words: [String]", "parameterSignatureWithoutNames": "words: [String]", "inputTypes": "[String]", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "words", "call": "words: words", "parameters": [CuckooGeneratorFramework.MethodParameter(label: Optional("words"), name: "words", type: "[String]", range: CountableRange(633..<648), nameRange: CountableRange(633..<638))], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func show(words: [String])  {
        
            return cuckoo_manager.call("show(words: [String])",
                parameters: (words),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    
    // ["name": "showError", "returnSignature": "", "fullyQualifiedName": "showError()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func showError()  {
        
            return cuckoo_manager.call("showError()",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_CreateWalletPresenterProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func show<M1: Cuckoo.Matchable>(words: M1) -> Cuckoo.ProtocolStubNoReturnFunction<([String])> where M1.MatchedType == [String] {
	        let matchers: [Cuckoo.ParameterMatcher<([String])>] = [wrap(matchable: words) { $0 }]
	        return .init(stub: cuckoo_manager.createStub(for: MockCreateWalletPresenterProtocol.self, method: "show(words: [String])", parameterMatchers: matchers))
	    }
	    
	    func showError() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockCreateWalletPresenterProtocol.self, method: "showError()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_CreateWalletPresenterProtocol: Cuckoo.VerificationProxy {
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
	    func showError() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showError()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class CreateWalletPresenterProtocolStub: CreateWalletPresenterProtocol {
    

    

    
     func show(words: [String])  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func showError()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockCreateWalletDataProviderProtocol: CreateWalletDataProviderProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = CreateWalletDataProviderProtocol
    typealias Stubbing = __StubbingProxy_CreateWalletDataProviderProtocol
    typealias Verification = __VerificationProxy_CreateWalletDataProviderProtocol
    let cuckoo_manager = Cuckoo.MockManager(hasParent: false)

    

    

    
    // ["name": "generateWords", "returnSignature": " -> [String]?", "fullyQualifiedName": "generateWords() -> [String]?", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Optional<[String]>", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubFunction"]
     func generateWords()  -> [String]? {
        
            return cuckoo_manager.call("generateWords() -> [String]?",
                parameters: (),
                superclassCall:
                    
                    Cuckoo.MockManager.crashOnProtocolSuperclassCall()
                    )
        
    }
    

	struct __StubbingProxy_CreateWalletDataProviderProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func generateWords() -> Cuckoo.ProtocolStubFunction<(), Optional<[String]>> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockCreateWalletDataProviderProtocol.self, method: "generateWords() -> [String]?", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_CreateWalletDataProviderProtocol: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func generateWords() -> Cuckoo.__DoNotUse<Optional<[String]>> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("generateWords() -> [String]?", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class CreateWalletDataProviderProtocolStub: CreateWalletDataProviderProtocol {
    

    

    
     func generateWords()  -> [String]? {
        return DefaultValueRegistry.defaultValue(for: Optional<[String]>.self)
    }
    
}


class MockCreateWalletDataProvider: CreateWalletDataProvider, Cuckoo.ClassMock {
    typealias MocksType = CreateWalletDataProvider
    typealias Stubbing = __StubbingProxy_CreateWalletDataProvider
    typealias Verification = __VerificationProxy_CreateWalletDataProvider
    let cuckoo_manager = Cuckoo.MockManager(hasParent: true)

    

    

    
    // ["name": "generateWords", "returnSignature": " -> [String]?", "fullyQualifiedName": "generateWords() -> [String]?", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Optional<[String]>", "isOptional": false, "stubFunction": "Cuckoo.ClassStubFunction"]
     override func generateWords()  -> [String]? {
        
            return cuckoo_manager.call("generateWords() -> [String]?",
                parameters: (),
                superclassCall:
                    
                    super.generateWords()
                    )
        
    }
    

	struct __StubbingProxy_CreateWalletDataProvider: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func generateWords() -> Cuckoo.ClassStubFunction<(), Optional<[String]>> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockCreateWalletDataProvider.self, method: "generateWords() -> [String]?", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_CreateWalletDataProvider: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func generateWords() -> Cuckoo.__DoNotUse<Optional<[String]>> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("generateWords() -> [String]?", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class CreateWalletDataProviderStub: CreateWalletDataProvider {
    

    

    
     override func generateWords()  -> [String]? {
        return DefaultValueRegistry.defaultValue(for: Optional<[String]>.self)
    }
    
}


// MARK: - Mocks generated from file: Wallet/Modules/Guest/GuestRouter.swift at 2018-06-05 09:37:00 +0000


import Cuckoo
@testable import Wallet

import Foundation

class MockGuestRouter: GuestRouter, Cuckoo.ClassMock {
    typealias MocksType = GuestRouter
    typealias Stubbing = __StubbingProxy_GuestRouter
    typealias Verification = __VerificationProxy_GuestRouter
    let cuckoo_manager = Cuckoo.MockManager(hasParent: true)

    

    

    
    // ["name": "showCreateWallet", "returnSignature": "", "fullyQualifiedName": "showCreateWallet()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ClassStubNoReturnFunction"]
     override func showCreateWallet()  {
        
            return cuckoo_manager.call("showCreateWallet()",
                parameters: (),
                superclassCall:
                    
                    super.showCreateWallet()
                    )
        
    }
    
    // ["name": "showRestoreWallet", "returnSignature": "", "fullyQualifiedName": "showRestoreWallet()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": true, "hasClosureParams": false, "@type": "ClassMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ClassStubNoReturnFunction"]
     override func showRestoreWallet()  {
        
            return cuckoo_manager.call("showRestoreWallet()",
                parameters: (),
                superclassCall:
                    
                    super.showRestoreWallet()
                    )
        
    }
    

	struct __StubbingProxy_GuestRouter: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func showCreateWallet() -> Cuckoo.ClassStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestRouter.self, method: "showCreateWallet()", parameterMatchers: matchers))
	    }
	    
	    func showRestoreWallet() -> Cuckoo.ClassStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestRouter.self, method: "showRestoreWallet()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_GuestRouter: Cuckoo.VerificationProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	    private let callMatcher: Cuckoo.CallMatcher
	    private let sourceLocation: Cuckoo.SourceLocation
	
	    init(manager: Cuckoo.MockManager, callMatcher: Cuckoo.CallMatcher, sourceLocation: Cuckoo.SourceLocation) {
	        self.cuckoo_manager = manager
	        self.callMatcher = callMatcher
	        self.sourceLocation = sourceLocation
	    }
	
	    
	
	    
	    @discardableResult
	    func showCreateWallet() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showCreateWallet()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func showRestoreWallet() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showRestoreWallet()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class GuestRouterStub: GuestRouter {
    

    

    
     override func showCreateWallet()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     override func showRestoreWallet()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}


class MockGuestInteractorProtocol: GuestInteractorProtocol, Cuckoo.ProtocolMock {
    typealias MocksType = GuestInteractorProtocol
    typealias Stubbing = __StubbingProxy_GuestInteractorProtocol
    typealias Verification = __VerificationProxy_GuestInteractorProtocol
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
    

	struct __StubbingProxy_GuestInteractorProtocol: Cuckoo.StubbingProxy {
	    private let cuckoo_manager: Cuckoo.MockManager
	
	    init(manager: Cuckoo.MockManager) {
	        self.cuckoo_manager = manager
	    }
	    
	    
	    func createNewWalletDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestInteractorProtocol.self, method: "createNewWalletDidTap()", parameterMatchers: matchers))
	    }
	    
	    func restoreWalletDidTap() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestInteractorProtocol.self, method: "restoreWalletDidTap()", parameterMatchers: matchers))
	    }
	    
	}

	struct __VerificationProxy_GuestInteractorProtocol: Cuckoo.VerificationProxy {
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

 class GuestInteractorProtocolStub: GuestInteractorProtocol {
    

    

    
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

    

    

    
    // ["name": "showCreateWallet", "returnSignature": "", "fullyQualifiedName": "showCreateWallet()", "parameterSignature": "", "parameterSignatureWithoutNames": "", "inputTypes": "", "isThrowing": false, "isInit": false, "isOverriding": false, "hasClosureParams": false, "@type": "ProtocolMethod", "accessibility": "", "parameterNames": "", "call": "", "parameters": [], "returnType": "Void", "isOptional": false, "stubFunction": "Cuckoo.ProtocolStubNoReturnFunction"]
     func showCreateWallet()  {
        
            return cuckoo_manager.call("showCreateWallet()",
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
	    
	    
	    func showCreateWallet() -> Cuckoo.ProtocolStubNoReturnFunction<()> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return .init(stub: cuckoo_manager.createStub(for: MockGuestRouterProtocol.self, method: "showCreateWallet()", parameterMatchers: matchers))
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
	    func showCreateWallet() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showCreateWallet()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	    @discardableResult
	    func showRestoreWallet() -> Cuckoo.__DoNotUse<Void> {
	        let matchers: [Cuckoo.ParameterMatcher<Void>] = []
	        return cuckoo_manager.verify("showRestoreWallet()", callMatcher: callMatcher, parameterMatchers: matchers, sourceLocation: sourceLocation)
	    }
	    
	}

}

 class GuestRouterProtocolStub: GuestRouterProtocol {
    

    

    
     func showCreateWallet()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
     func showRestoreWallet()  {
        return DefaultValueRegistry.defaultValue(for: Void.self)
    }
    
}

