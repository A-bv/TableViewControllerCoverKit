// swift-tools-version: 5.9
//
// iOS-only (UIKit). `swift build` / `swift test` target macOS and fail with "no such module
// 'UIKit'". Run the tests on an iOS simulator:
//   xcodebuild test -scheme TableViewControllerCoverKit -destination 'platform=iOS Simulator,name=iPhone 16'
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
