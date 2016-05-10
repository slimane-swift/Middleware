import PackageDescription

let package = Package(
    name: "Middleware",
    dependencies: [
        .Package(url: "https://github.com/noppoMan/HTTP.git", majorVersion: 0, minor: 7),
        .Package(url: "https://github.com/slimane-swift/JSON.git", majorVersion: 0, minor: 7)
    ]
)
