import XCTest
@testable import TableViewControllerCoverKit

@MainActor
final class CoverImageControllerTests: XCTestCase {

    private func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 1200)).image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 1200))
        }
    }

    func testSetCoverImage_installsTheBackgroundAndPushesContentDown() {
        let tableView = UITableView()
        let host = UIViewController()
        host.view.addSubview(tableView)
        let cover = CoverImageController(tableView: tableView, host: host)

        cover.setCoverImage(makeImage())

        XCTAssertNotNil(tableView.backgroundView)
        XCTAssertGreaterThan(tableView.contentInset.top, 0)
    }

    func testSetCoverImage_rendersAtDisplaySizeNotSourceSize() {
        let tableView = UITableView()
        let host = UIViewController()
        host.view.addSubview(tableView)
        let cover = CoverImageController(tableView: tableView, host: host)

        cover.setCoverImage(makeImage())

        let imageView = tableView.backgroundView?.subviews.first as? UIImageView
        XCTAssertLessThan(imageView?.image?.size.width ?? .infinity, 1200)
    }

    func testStatusBarStyle_isLightOverTheImageAndDefaultPastIt() {
        let tableView = UITableView()
        let host = UIViewController()
        host.view.addSubview(tableView)
        let cover = CoverImageController(tableView: tableView, host: host)
        cover.setCoverImage(makeImage())

        tableView.contentOffset = CGPoint(x: 0, y: -400)   // over the image
        cover.scrollViewDidScroll()
        XCTAssertEqual(cover.preferredStatusBarStyle, .lightContent)

        tableView.contentOffset = CGPoint(x: 0, y: 400)    // scrolled past it
        cover.scrollViewDidScroll()
        XCTAssertEqual(cover.preferredStatusBarStyle, .default)

        cover.suspendsCoverStatusBarStyle = true
        XCTAssertEqual(cover.preferredStatusBarStyle, .default)
    }

    func testOverscroll_stretchesTheCoverWithTheSpringEffect() {
        let tableView = UITableView()
        let host = UIViewController()
        host.view.addSubview(tableView)
        let cover = CoverImageController(tableView: tableView, host: host)
        cover.setCoverImage(makeImage())

        let imageView = tableView.backgroundView?.subviews.first as? UIImageView
        let restingHeight = imageView?.frame.height ?? 0

        tableView.contentOffset = CGPoint(x: 0, y: -UIScreen.main.bounds.height)
        cover.scrollViewDidScroll()
        XCTAssertGreaterThan(imageView?.frame.height ?? 0, restingHeight)
    }
}
