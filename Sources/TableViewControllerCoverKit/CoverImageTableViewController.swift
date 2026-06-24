import UIKit

open class CoverImageTableViewController: UITableViewController {

    public var expandedBarHeight: CGFloat?

    public var barBackgroundColor: UIColor = .systemBackground {
        didSet { lastAppliedBarKey = nil }
    }

    public var suspendsCoverStatusBarStyle = false {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    private var barFadeProgress: CGFloat = 0 {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    open override var preferredStatusBarStyle: UIStatusBarStyle {
        if suspendsCoverStatusBarStyle { return .default }
        return barFadeProgress < 0 ? .lightContent : .default
    }

    private enum Constants {
        static let scrollIndicatorPadding: CGFloat = 20
        static let vignetteIntensity = 0.12
        static let vignetteRadius = 0.2
        static let barFadeDistance: CGFloat = 50
        static let coverOverlap: CGFloat = 22
    }

    private var coverImageView = UIImageView()
    private let coverBackgroundView = UIView()
    private static let vignetteContext = CIContext()

    private var sourceImage: UIImage?
    private var installedCoverSize: CGSize = .zero
    private var hasPositionedContent = false
    private var lastAppliedBarKey: CGFloat?
    private var maxSafeAreaTopSeen: CGFloat = 0

    public func setCoverImage(_ image: UIImage?) {
        if let image { sourceImage = image }
        installedCoverSize = .zero
        installCoverIfNeeded()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        installCoverIfNeeded()
    }

    private func installCoverIfNeeded() {
        guard let sourceImage else { return }
        let size = coverDisplaySize
        guard size.width > 0, size.height > 0, size != installedCoverSize else { return }
        installedCoverSize = size

        coverImageView.image = vignetted(resizedToDisplay(sourceImage))
        coverImageView.contentMode = .scaleAspectFill
        coverImageView.clipsToBounds = true
        coverImageView.frame = CGRect(origin: .zero, size: size)
        if coverImageView.superview == nil { coverBackgroundView.addSubview(coverImageView) }
        tableView.backgroundView = coverBackgroundView
        configureContentInsets()

        if !hasPositionedContent {
            hasPositionedContent = true
            tableView.contentOffset = CGPoint(x: 0, y: -tableView.adjustedContentInset.top)
        }
    }

    private var coverDisplaySize: CGSize {
        CGSize(width: view.bounds.width, height: view.bounds.height / 2 + Constants.coverOverlap)
    }

    private func configureContentInsets() {
        maxSafeAreaTopSeen = max(maxSafeAreaTopSeen, view.safeAreaInsets.top)
        let barArea = expandedBarHeight.map { $0 + statusBarHeight } ?? maxSafeAreaTopSeen
        let halfHeight = view.bounds.height / 2
        let indicator = halfHeight - (barArea - statusBarHeight) + Constants.coverOverlap + Constants.scrollIndicatorPadding
        tableView.contentInset = UIEdgeInsets(top: halfHeight - barArea, left: 0, bottom: 0, right: 0)
        tableView.verticalScrollIndicatorInsets = UIEdgeInsets(top: indicator, left: 0, bottom: 0, right: 0)
    }

    private var statusBarHeight: CGFloat {
        let scene = view.window?.windowScene
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
        return scene?.statusBarManager?.statusBarFrame.height ?? 0
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastAppliedBarKey = nil
        applyBarTransparency()
    }

    open override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.y
        let barHeight = navigationController?.navigationBar.frame.height ?? 0
        barFadeProgress = Self.fadeProgress(offset: offset, barHeight: barHeight, statusBarHeight: statusBarHeight)
        applyBarTransparency()

        let restOffset = -scrollView.adjustedContentInset.top
        coverImageView.frame.size.height = coverDisplaySize.height + max(0, restOffset - offset)
    }

    static func fadeProgress(offset: CGFloat, barHeight: CGFloat, statusBarHeight: CGFloat) -> CGFloat {
        min(1, (offset + barHeight + 2 * statusBarHeight) / Constants.barFadeDistance)
    }

    private func applyBarTransparency() {
        let key: CGFloat = barFadeProgress < 0 ? -1 : barFadeProgress
        guard key != lastAppliedBarKey else { return }
        lastAppliedBarKey = key

        let overImage = barFadeProgress < 0
        let textColor: UIColor = overImage ? .white : .label.withAlphaComponent(barFadeProgress)
        let background: UIColor = overImage ? .clear : barBackgroundColor.withAlphaComponent(barFadeProgress)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: textColor]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = textColor
    }

    private func vignetted(_ image: UIImage) -> UIImage {
        guard let input = CIImage(image: image), let filter = CIFilter(name: "CIVignetteEffect") else { return image }
        filter.setValue(input, forKey: kCIInputImageKey)
        filter.setValue(Constants.vignetteIntensity, forKey: "inputIntensity")
        filter.setValue(Constants.vignetteRadius, forKey: "inputRadius")
        guard let output = filter.outputImage,
              let cg = Self.vignetteContext.createCGImage(output, from: input.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }

    private func resizedToDisplay(_ image: UIImage) -> UIImage {
        let size = coverDisplaySize
        return UIGraphicsImageRenderer(size: size).image { _ in
            let scale = max(size.width / image.size.width, size.height / image.size.height)
            let scaled = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: (size.width - scaled.width) / 2, y: (size.height - scaled.height) / 2)
            image.draw(in: CGRect(origin: origin, size: scaled))
        }
    }
}
