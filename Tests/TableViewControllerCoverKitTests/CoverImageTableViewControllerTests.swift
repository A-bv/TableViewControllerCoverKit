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

    /// The cover normally renders off the main thread; tests render synchronously so assertions
    /// don't race a wall-clock timeout (which is flaky on slow/contended CI runners).
    private func renderingSynchronously(_ sut: CoverImageTableViewController) {
        sut.rendersCoverSynchronously = true
    }

    func testSetCoverImage_installsTheBackgroundAndPushesContentDown() {
        let sut = makeSUT()
        sut.setCoverImage(makeImage())

        XCTAssertNotNil(sut.tableView.backgroundView)
        XCTAssertGreaterThan(sut.tableView.contentInset.top, 0)
    }

    func testSetCoverImage_rendersAtDisplaySizeNotSourceSize() {
        let sut = makeSUT()
        renderingSynchronously(sut)
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
        XCTAssertEqual(cover()?.frame.height ?? 0, 390 / 2 + 22, accuracy: 0.5)
    }

    func testExpandedBarHeight_overrideChangesTheContentInset() {
        let derived = makeSUT()
        derived.setCoverImage(makeImage())
        let derivedInset = derived.tableView.contentInset.top

        let overridden = makeSUT()
        overridden.expandedBarHeight = 200  // manual override instead of the derived value
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

    func testSetCoverImage_ignoresAnEmptyImage() {
        let sut = makeSUT()
        sut.setCoverImage(UIImage())  // empty (zero-size) input: nothing should install

        XCTAssertNil(sut.tableView.backgroundView)
        XCTAssertEqual(sut.tableView.contentInset.top, 0)
    }

    func testExpandedBarHeight_neverDrivesContentInsetNegative() {
        let sut = makeSUT(width: 390, height: 400)  // deliberately short view
        sut.expandedBarHeight = 1000  // absurdly large override
        sut.setCoverImage(makeImage())

        XCTAssertGreaterThanOrEqual(sut.tableView.contentInset.top, 0)
        XCTAssertGreaterThanOrEqual(sut.tableView.verticalScrollIndicatorInsets.top, 0)
    }

    func testContentInsets_recomputeOnLayoutNotJustOnResize() {
        let sut = makeSUT()
        renderingSynchronously(sut)
        sut.setCoverImage(makeImage())
        let before = sut.tableView.contentInset.top

        // A value that affects the inset changes after the cover is installed. A layout pass (from
        // any source — e.g. the safe area resolving once in a window) must pick it up, even though
        // the cover size hasn't changed and the size-gated install short-circuits.
        sut.expandedBarHeight = 300
        sut.viewDidLayoutSubviews()

        XCTAssertNotEqual(before, sut.tableView.contentInset.top)
    }

    func testCover_isHiddenFromVoiceOver() {
        let sut = makeSUT()
        sut.setCoverImage(makeImage())

        let cover = sut.tableView.backgroundView?.subviews.first as? UIImageView
        XCTAssertEqual(cover?.isAccessibilityElement, false)
    }

    func testOverscrollStretch_isSuppressedUnderReduceMotion() {
        // Overscrolling past the resting offset stretches the cover, unless Reduce Motion is on.
        let normal = CoverImageTableViewController.overscrollStretch(
            restOffset: 0, offset: -120, reduceMotion: false)
        let reduced = CoverImageTableViewController.overscrollStretch(
            restOffset: 0, offset: -120, reduceMotion: true)

        XCTAssertGreaterThan(normal, 0)
        XCTAssertEqual(reduced, 0)
    }

    /// Exercises the real, shipping async render path (the flag left off) that every other test
    /// bypasses by rendering synchronously — guarding a regression that breaks the hop back to the
    /// main actor or never assigns the rendered image.
    func testSetCoverImage_asyncPathAssignsTheRenderedImage() async {
        let sut = makeSUT()
        sut.setCoverImage(makeImage())  // flag left off: real off-main render + main-actor apply
        let cover = sut.tableView.backgroundView?.subviews.first as? UIImageView

        // Poll until the off-main render assigns the image, breaking as soon as it does. The cap is
        // deliberately generous: a cold, contended CI runner's first Core Image render can take
        // several seconds, and the wait only reaches the cap if the async path is actually broken.
        for _ in 0..<600 {
            if cover?.image != nil { break }
            try? await Task.sleep(nanoseconds: 25_000_000)  // 25ms, capped at ~15s total
        }
        XCTAssertNotNil(cover?.image, "async render never assigned the cover image")
    }

    /// The vignette darkens the edges, so a corner pixel must be darker than the centre. This pins
    /// that the Core Image stage actually runs — its failure path silently returns the input image,
    /// which would otherwise pass every other assertion.
    func testVignette_darkensTheCornersRelativeToTheCentre() throws {
        let sut = makeSUT()
        renderingSynchronously(sut)
        sut.setCoverImage(makeImage())

        let cover = try XCTUnwrap((sut.tableView.backgroundView?.subviews.first as? UIImageView)?.image)
        let centre = pixelBrightness(cover, atX: 0.5, y: 0.5)
        let corner = pixelBrightness(cover, atX: 0.02, y: 0.02)
        // Require a visible gap: a uniform dim or a silent no-op (which returns the flat input image)
        // leaves corner == centre and must not pass.
        XCTAssertLessThan(
            corner, centre - 5, "vignette should darken the corner (corner \(corner) vs centre \(centre))")
    }

    /// Average brightness (0–255) of a single pixel of `image`, sampled at fractional coordinates.
    private func pixelBrightness(_ image: UIImage, atX fx: CGFloat, y fy: CGFloat) -> CGFloat {
        guard let cg = image.cgImage else { return .nan }
        let col = Int((CGFloat(cg.width) - 1) * fx)
        let row = Int((CGFloat(cg.height) - 1) * fy)
        var px: [UInt8] = [0, 0, 0, 0]
        let ctx = CGContext(
            data: &px, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        ctx?.draw(cg, in: CGRect(x: -col, y: -row, width: cg.width, height: cg.height))
        return (CGFloat(px[0]) + CGFloat(px[1]) + CGFloat(px[2])) / 3
    }

    // MARK: - Snapshot

    /// The rendered cover (resize plus vignette from a fixed gradient) must match a committed
    /// reference image, so a visual regression the numeric tests miss still fails the suite.
    func testSnapshot_renderedCoverMatchesReference() throws {
        let sut = makeSUT()
        renderingSynchronously(sut)
        sut.setCoverImage(gradientCover())

        let cover = try XCTUnwrap((sut.tableView.backgroundView?.subviews.first as? UIImageView)?.image)
        try assertSnapshot(cover, named: "rendered-cover")
    }

    /// A deterministic cover source (a code-drawn gradient, no assets or fonts) so the render is
    /// stable enough to snapshot across machines.
    private func gradientCover(_ side: CGFloat = 400) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: side, height: side)).image { context in
            let colors = [UIColor.systemIndigo.cgColor, UIColor.systemTeal.cgColor] as CFArray
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            context.cgContext.drawLinearGradient(
                gradient, start: .zero, end: CGPoint(x: side, y: side), options: [])
        }
    }

    /// Records the reference on first run, then fails if the image drifts beyond a tolerance wide
    /// enough to absorb GPU and anti-aliasing differences between machines.
    private func assertSnapshot(
        _ image: UIImage, named name: String,
        filePath: String = #filePath, file: StaticString = #filePath, line: UInt = #line
    ) throws {
        let dir = URL(fileURLWithPath: filePath).deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
        let reference = dir.appendingPathComponent("\(name).png")

        guard FileManager.default.fileExists(atPath: reference.path) else {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try downsampled(image, grid: 100).pngData()?.write(to: reference)
            XCTFail("Recorded a reference snapshot at \(reference.path). Commit it and re-run.", file: file, line: line)
            return
        }

        let expected = try XCTUnwrap(UIImage(contentsOfFile: reference.path))
        let (differing, total) = channelDifference(image, expected)
        let fraction = total == 0 ? 1 : Double(differing) / Double(total)
        XCTAssertLessThanOrEqual(
            fraction, 0.03, "cover snapshot drifted by \(Int(fraction * 100))%", file: file, line: line)
    }

    /// Downsamples both images to a small fixed grid and counts colour channels that differ beyond a
    /// threshold. The downsample blurs away sub-pixel noise while keeping real changes visible.
    private func channelDifference(
        _ lhs: UIImage, _ rhs: UIImage, grid: Int = 100, tolerance: Int = 16
    ) -> (Int, Int) {
        let left = normalizedPixels(lhs, grid: grid)
        let right = normalizedPixels(rhs, grid: grid)
        guard !left.isEmpty, left.count == right.count else { return (1, 1) }
        var differing = 0
        for i in left.indices where abs(Int(left[i]) - Int(right[i])) > tolerance { differing += 1 }
        return (differing, left.count)
    }

    /// A small, scale-1 copy of `image`, so the committed reference stays a few KB instead of megabytes.
    private func downsampled(_ image: UIImage, grid: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: grid, height: grid), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: grid, height: grid))
        }
    }

    private func normalizedPixels(_ image: UIImage, grid: Int) -> [UInt8] {
        guard let cg = image.cgImage else { return [] }
        var data = [UInt8](repeating: 0, count: grid * grid * 4)
        let ctx = CGContext(
            data: &data, width: grid, height: grid, bitsPerComponent: 8, bytesPerRow: grid * 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        ctx?.interpolationQuality = .high
        ctx?.draw(cg, in: CGRect(x: 0, y: 0, width: grid, height: grid))
        return data
    }
}
