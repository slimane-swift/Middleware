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

func makeKey(key: String) -> String {
    return "Slimane.Middleware\(key)"
}

public enum MiddlewareChainResult {
    case Chain(Response)
    case Error(ErrorProtocol)
}

public typealias MiddlewareChain = MiddlewareChainResult -> ()
public typealias MiddlewareHandlerType = (req: Request, res: Response, next: MiddlewareChain) -> ()

public protocol MiddlewareType: AsyncMiddleware {
    func respond(req: Request, res: Response, next: MiddlewareChain)
}

extension Response {
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
    
    public mutating func body(text text: String) {
        headers["content-type"] = Header("text/plain")
        self.body = .buffer(Data(text))
    }
    
    public mutating func body(html html: String) {
        headers["content-type"] = Header("text/html")
        self.body = .buffer(Data(html))
    }

    public mutating func body(json json: JSON) {
        headers["content-type"] = Header("application/json")
        let serialized = JSONSerializer().serializeToString(json)
        self.body = .buffer(serialized.data)
    }
}

extension MiddlewareType {
    public func respond(to request: Request, chainingTo next: AsyncResponder, result: (Void throws -> Response) -> Void) {
        next.respond(to: request, result: {
            do {
                let response = try $0()
                if response.isIntercepted {
                    return result { response }
                }

                self.respond(request, res: response) {
                    if case .Chain(var response) = $0 {
                        if case .buffer(let data) = response.body {
                            if !data.isEmpty {
                                response.isIntercepted = true
                            }
                        }
                        result { response }
                    }
                    else if case .Error(let error) = $0 {
                        result { throw error }
                    }
                }
            } catch {
                result { throw error }
            }
        })
    }
}

public struct BasicMiddleware: MiddlewareType {
    let handler: MiddlewareHandlerType

    public init(handler: MiddlewareHandlerType){
        self.handler = handler
    }

    public func respond(req: Request, res: Response, next: MiddlewareChain) {
        handler(req: req, res: res, next: next)
    }
}
