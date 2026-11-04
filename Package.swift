// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "simulators",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "simulators", targets: ["simulators"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "simulators",
            dependencies: [
                "SimulatorsKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .target(name: "SimulatorsKit")
    ],
    swiftLanguageModes: [.v6]
)
