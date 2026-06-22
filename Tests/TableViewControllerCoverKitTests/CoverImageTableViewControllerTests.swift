import XCTest
@testable import TableViewControllerCoverKit

@MainActor
final class CoverImageTableViewControllerTests: XCTestCase {

    /// A controller with a real, laid-out view so the cover (which now sizes off the view's
    /// own bounds) has something to render into.
    private func makeSUT(width: CGFloat = 390, height: CGFloat = 844) -> CoverImageTableViewController {
        let sut = CoverImageTableViewController()
        sut.view.frame = CGRect(x: 0, y: 0, width: width, height: height)
        sut.view.layoutIfNeeded()
        return sut
    }

    private func makeImage(_ side: CGFloat = 1200) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    func testSetCoverImage_installsTheBackgroundAndPushesContentDown() {
        let sut = makeSUT()
        sut.setCoverImage(makeImage())

        XCTAssertNotNil(sut.tableView.backgroundView)
        XCTAssertGreaterThan(sut.tableView.contentInset.top, 0)
    }

    func testSetCoverImage_rendersAtDisplaySizeNotSourceSize() {
        let sut = makeSUT()
        sut.setCoverImage(makeImage())

        let cover = sut.tableView.backgroundView?.subviews.first as? UIImageView
        XCTAssertLessThan(cover?.image?.size.width ?? .infinity, 1200)
    }

    func testStatusBarStyle_isLightOverTheImageAndDefaultPastIt() {
        let sut = makeSUT()
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
        let sut = makeSUT()
        sut.setCoverImage(makeImage())

        let cover = sut.tableView.backgroundView?.subviews.first as? UIImageView
        let restingHeight = cover?.frame.height ?? 0

        sut.tableView.contentOffset = CGPoint(x: 0, y: -sut.view.bounds.height)
        sut.scrollViewDidScroll(sut.tableView)

        XCTAssertGreaterThan(cover?.frame.height ?? 0, restingHeight)
    }

    func testBarAppearance_fadesInAsTheListScrollsOverTheImage() {
        let sut = makeSUT()
        sut.setCoverImage(makeImage())

        // Over the image: the bar is transparent (a clear background reads back as nil).
        sut.tableView.contentOffset = CGPoint(x: 0, y: -400)
        sut.scrollViewDidScroll(sut.tableView)
        let overImageAlpha = sut.navigationItem.standardAppearance?.backgroundColor?.cgColor.alpha ?? 0

        // Scrolled well past the image: the bar is opaque.
        sut.tableView.contentOffset = CGPoint(x: 0, y: 400)
        sut.scrollViewDidScroll(sut.tableView)
        let scrolledAlpha = sut.navigationItem.standardAppearance?.backgroundColor?.cgColor.alpha ?? 0

        XCTAssertEqual(overImageAlpha, 0, accuracy: 0.01)
        XCTAssertEqual(scrolledAlpha, 1, accuracy: 0.01)
    }

    func testResize_reRendersCoverAndInsetsForTheNewBounds() {
        let sut = makeSUT(width: 390, height: 844)
        sut.setCoverImage(makeImage())

        let cover = { sut.tableView.backgroundView?.subviews.first as? UIImageView }
        let portraitInset = sut.tableView.contentInset.top
        let portraitCoverHeight = cover()?.frame.height

        // Simulate a rotation / resize to a shorter, wider layout.
        sut.view.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        sut.view.layoutIfNeeded()

        XCTAssertNotEqual(portraitInset, sut.tableView.contentInset.top)
        XCTAssertNotEqual(portraitCoverHeight, cover()?.frame.height)
        XCTAssertEqual(cover()?.frame.height ?? 0, 390 / 2 + sut.coverCornerRadius, accuracy: 0.5)
    }
}
