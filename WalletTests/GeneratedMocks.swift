// MARK: - Mocks generated from file: Wallet/Modules/Guest/GuestRouter.swift at 2018-06-05 08:44:37 +0000


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

