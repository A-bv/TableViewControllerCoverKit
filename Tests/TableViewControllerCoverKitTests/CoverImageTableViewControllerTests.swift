import XCTest
@testable import TableViewControllerCoverKit

@MainActor
final class CoverImageTableViewControllerTests: XCTestCase {

    private func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1200, height: 1200)).image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1200, height: 1200))
        }
    }

    func testSetCoverImage_installsTheBackgroundAndPushesContentDown() {
        let sut = CoverImageTableViewController()
        sut.loadViewIfNeeded()

        sut.setCoverImage(makeImage())

        XCTAssertNotNil(sut.tableView.backgroundView)
        XCTAssertGreaterThan(sut.tableView.contentInset.top, 0)
    }

    func testSetCoverImage_rendersAtDisplaySizeNotSourceSize() {
        let sut = CoverImageTableViewController()
        sut.loadViewIfNeeded()

        sut.setCoverImage(makeImage())

        let cover = sut.tableView.backgroundView?.subviews.first as? UIImageView
        let rendered = try? XCTUnwrap(cover?.image)
        XCTAssertLessThan(rendered?.size.width ?? .infinity, 1200)
    }

    func testStatusBarStyle_isLightOverTheImageAndDefaultPastIt() {
        let sut = CoverImageTableViewController()
        sut.loadViewIfNeeded()
        sut.setCoverImage(makeImage())

        sut.tableView.contentOffset = CGPoint(x: 0, y: -400)
        sut.scrollViewDidScroll(sut.tableView)
        XCTAssertEqual(sut.preferredStatusBarStyle, .lightContent)

        sut.tableView.contentOffset = CGPoint(x: 0, y: 400)
        sut.scrollViewDidScroll(sut.tableView)
        XCTAssertEqual(sut.preferredStatusBarStyle, .default)

        sut.suspendsCoverStatusBarStyle = true
        XCTAssertEqual(sut.preferredStatusBarStyle, .default)
    }

    func testOverscroll_stretchesTheCoverWithTheSpringEffect() {
        let sut = CoverImageTableViewController()
        sut.loadViewIfNeeded()
        sut.setCoverImage(makeImage())

        sut.tableView.contentOffset = CGPoint(x: 0, y: -UIScreen.main.bounds.height)
        sut.scrollViewDidScroll(sut.tableView)

        let cover = sut.tableView.backgroundView?.subviews.first as? UIImageView
        XCTAssertEqual(cover?.frame.height, UIScreen.main.bounds.height + sut.coverCornerRadius)
    }
}
