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

    /// The cover is now rendered off the main thread, so wait until the image lands. Uses a
    /// predicate expectation so the main run loop (and thus the main dispatch queue that delivers
    /// the rendered image) is actually drained while we wait.
    private func wait(until condition: @escaping () -> Bool, timeout: TimeInterval = 3) {
        let predicate = NSPredicate { _, _ in condition() }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        wait(for: [expectation], timeout: timeout)
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
        wait(until: { cover?.image != nil })
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
        XCTAssertEqual(cover()?.frame.height ?? 0, 390 / 2 + 22, accuracy: 0.5)
    }

    func testExpandedBarHeight_overrideChangesTheContentInset() {
        let derived = makeSUT()
        derived.setCoverImage(makeImage())
        let derivedInset = derived.tableView.contentInset.top

        let overridden = makeSUT()
        overridden.expandedBarHeight = 200          // manual override instead of the derived value
        overridden.setCoverImage(makeImage())

        XCTAssertNotEqual(derivedInset, overridden.tableView.contentInset.top)
    }

    func testFadeProgress_transparentOverImage_opaquePastTheBar() {
        // Resting over the image: transparent.
        XCTAssertLessThan(
            CoverImageTableViewController.fadeProgress(offset: -400, barHeight: 44, statusBarHeight: 54), 0)
        // Scrolled up past the bar: opaque.
        XCTAssertEqual(
            CoverImageTableViewController.fadeProgress(offset: 400, barHeight: 44, statusBarHeight: 54),
            1, accuracy: 0.001)
    }

    func testFadeInsideNavigationController_isLightOverImageThenOpaquePastIt() {
        let sut = CoverImageTableViewController()
        let nav = UINavigationController(rootViewController: sut)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        sut.view.layoutIfNeeded()
        sut.setCoverImage(makeImage())
        sut.view.layoutIfNeeded()

        // Over the cover: light status bar, transparent bar.
        sut.tableView.contentOffset = CGPoint(x: 0, y: -400)
        sut.scrollViewDidScroll(sut.tableView)
        XCTAssertEqual(sut.preferredStatusBarStyle, .lightContent)

        // Scrolled up past the image: default status bar, opaque bar.
        sut.tableView.contentOffset = CGPoint(x: 0, y: 600)
        sut.scrollViewDidScroll(sut.tableView)
        XCTAssertEqual(sut.preferredStatusBarStyle, .default)
        XCTAssertEqual(sut.navigationItem.standardAppearance?.backgroundColor?.cgColor.alpha ?? 0, 1, accuracy: 0.01)
    }

    func testNavigationBarTintColor_isRestoredWhenTheControllerDisappears() {
        let sut = CoverImageTableViewController()
        let nav = UINavigationController(rootViewController: sut)
        sut.view.layoutIfNeeded()
        sut.setCoverImage(makeImage())

        let original = UIColor.systemRed
        nav.navigationBar.tintColor = original
        sut.viewWillAppear(false)

        // Over the cover the bar tint is forced (white), diverging from the original.
        sut.tableView.contentOffset = CGPoint(x: 0, y: -400)
        sut.scrollViewDidScroll(sut.tableView)
        XCTAssertNotEqual(nav.navigationBar.tintColor, original)

        // On the way out it must be put back so it doesn't bleed into the next controller.
        sut.viewWillDisappear(false)
        XCTAssertEqual(nav.navigationBar.tintColor, original)
    }

    func testCoverStatusBarStyle_isConfigurableForLightCovers() {
        let sut = makeSUT()
        sut.setCoverImage(makeImage())
        sut.coverStatusBarStyle = .darkContent

        sut.tableView.contentOffset = CGPoint(x: 0, y: -400)
        sut.scrollViewDidScroll(sut.tableView)
        XCTAssertEqual(sut.preferredStatusBarStyle, .darkContent)
    }

    func testExpandedBarHeight_neverDrivesContentInsetNegative() {
        let sut = makeSUT(width: 390, height: 400)   // deliberately short view
        sut.expandedBarHeight = 1000                 // absurdly large override
        sut.setCoverImage(makeImage())

        XCTAssertGreaterThanOrEqual(sut.tableView.contentInset.top, 0)
        XCTAssertGreaterThanOrEqual(sut.tableView.verticalScrollIndicatorInsets.top, 0)
    }
}
