// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TableViewControllerCoverKit",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "TableViewControllerCoverKit", targets: ["TableViewControllerCoverKit"]),
    ],
    targets: [
        .target(name: "TableViewControllerCoverKit"),
        .testTarget(name: "TableViewControllerCoverKitTests", dependencies: ["TableViewControllerCoverKit"]),
    ]
)
