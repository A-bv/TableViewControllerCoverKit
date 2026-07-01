// swift-tools-version: 5.9
//
// iOS-only (UIKit). `swift build` / `swift test` target macOS and fail with "no such module
// 'UIKit'". Run the tests on any installed iOS simulator (list them with
// `xcrun simctl list devices available`):
//   xcodebuild test -scheme TableViewControllerCoverKit -destination 'platform=iOS Simulator,name=iPhone 17'
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
