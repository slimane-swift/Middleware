# Middleware
MiddleareType for Slimane


## Usage

```swift
struct AccessLogMiddleware: MiddlewareType {
    public func respond(req: Request, res: Response, next: MiddlewareChain) {
      print(req.uri.path ?? "/")
      next(.Chain(req, res))
    }
}
```

## Apis

### MiddlewareChainResult

Middleware Chain Result Type that enable to control middleware chain cycle

```swift
public enum MiddlewareChainResult {
    case Chain(Request, Response)
    case Intercept(Request, Response)
    case Error(ErrorProtocol)
}
```

* Chain: Go to next middleware chain with current request
* Intercept: Intercept the middleware chain with current Request/Response content
* Error: Intercept the middleware chain cycle and then respond error response


### MiddlewareType

Basic protocol for Slimane's Middleware

```swift
public protocol MiddlewareType: AsyncMiddleware {
    func respond(req: Request, res: Response, next: MiddlewareChain)
}
```


## Package.swift
```swift
import PackageDescription

let package = Package(
	name: "MyMiddleware",
	dependencies: [
      .Package(url: "https://github.com/slimane-swift/Middleware.git", majorVersion: 0, minor: 1),
  ]
)
```


## License

Middleware is released under the MIT license. See LICENSE for details.
