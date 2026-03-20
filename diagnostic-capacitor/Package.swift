// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NoesisDiagnosticCapacitor",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "NoesisDiagnosticCapacitor",
            targets: ["DiagnosticPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .target(
            name: "DiagnosticPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm")
            ],
            path: "ios/Sources/DiagnosticPlugin"
        ),
        .testTarget(
            name: "DiagnosticPluginTests",
            dependencies: ["DiagnosticPlugin"],
            path: "ios/Tests/DiagnosticPluginTests")
    ]
)