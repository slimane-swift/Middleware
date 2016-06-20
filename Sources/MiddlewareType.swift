//
//  MiddlewareType.swift
//  Middleware
//
//  Created by Yuki Takei on 4/15/16.
//
//

@_exported import C7
@_exported import S4
@_exported import HTTP
@_exported import JSON

func makeKey(_ key: String) -> String {
    return "Slimane.Middleware\(key)"
}

public enum MiddlewareChainResult {
    case chain(Request, Response)
    case intercept(Request, Response)
    case error(ErrorProtocol)
}

public typealias MiddlewareChain = (MiddlewareChainResult) -> ()
public typealias MiddlewareHandlerType = (req: Request, res: Response, next: MiddlewareChain) -> ()

public protocol MiddlewareType: AsyncMiddleware {
    func respond(_ req: Request, res: Response, next: MiddlewareChain)
}

public let __SLIMANE_INTERNAL_STORAGE_KEY = "Slimane.Internal.RetainingValue."
private let storageKeyForResponse = __SLIMANE_INTERNAL_STORAGE_KEY + "Response"

extension Request {
    internal var response: Response {
        get {
            return self.storage[storageKeyForResponse] as? Response ?? Response()
        }

        set {
            self.storage[storageKeyForResponse] = newValue
        }
    }

    public var isIntercepted: Bool {
        get {
            guard let intercepted = storage[makeKey("intercepted")] as? Bool else {
                return false
            }
            return intercepted
        }

        set {
            storage[makeKey("intercepted")] = newValue
        }
    }
}

extension MiddlewareType {
    public func respond(to request: Request, chainingTo next: AsyncResponder, result: ((Void) throws -> Response) -> Void) {
        if request.isIntercepted {
            result {
                request.response
            }
            return
        }

        let nextChain = { (request: Request) in
            next.respond(to: request) { chainedResponse in
                result {
                    try chainedResponse()
                }
            }
        }

        self.respond(request, res: request.response) {
            if case .chain(var request, let response) = $0 {
                request.storage[storageKeyForResponse] = response
                nextChain(request)
            }
            else if case .intercept(var request, let response) = $0 {
                request.isIntercepted = true
                request.storage[storageKeyForResponse] = response
                nextChain(request)
            }
            else if case .error(let error) = $0 {
                result {
                    throw error
                }
            }
        }
    }
}

public struct BasicMiddleware: MiddlewareType {
    let handler: MiddlewareHandlerType

    public init(handler: MiddlewareHandlerType){
        self.handler = handler
    }

    public func respond(_ req: Request, res: Response, next: MiddlewareChain) {
        handler(req: req, res: res, next: next)
    }
}
