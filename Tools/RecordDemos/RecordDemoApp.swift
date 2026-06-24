import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let largeTitle = ProcessInfo.processInfo.arguments.contains("--large-title")
        let controller = DemoController(largeTitle: largeTitle)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.prefersLargeTitles = largeTitle

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}

private final class DemoController: CoverImageTableViewController {
    private let largeTitle: Bool

    init(largeTitle: Bool) {
        self.largeTitle = largeTitle
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cover"
        navigationItem.largeTitleDisplayMode = largeTitle ? .always : .never
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 52
        setCoverImage(Self.coverImage())
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        runDemoAnimation()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        28
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = "Row \(indexPath.row + 1)"
        config.textProperties.font = .systemFont(ofSize: 17)
        cell.contentConfiguration = config
        cell.backgroundColor = .systemBackground
        return cell
    }

    private func runDemoAnimation() {
        tableView.layoutIfNeeded()
        let restOffset = -tableView.adjustedContentInset.top
        let upOffset = restOffset + 430
        let pullOffset = restOffset - 120

        tableView.setContentOffset(CGPoint(x: 0, y: restOffset), animated: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut]) {
                self.tableView.contentOffset = CGPoint(x: 0, y: upOffset)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
            UIView.animate(withDuration: 1.2, delay: 0, options: [.curveEaseInOut]) {
                self.tableView.contentOffset = CGPoint(x: 0, y: pullOffset)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
            UIView.animate(withDuration: 1.0, delay: 0, options: [.curveEaseOut]) {
                self.tableView.contentOffset = CGPoint(x: 0, y: restOffset)
            }
        }
    }

    private static func coverImage() -> UIImage {
        let size = CGSize(width: 900, height: 1200)
        return UIGraphicsImageRenderer(size: size).image { context in
            let colors = [
                UIColor(red: 0.18, green: 0.13, blue: 0.34, alpha: 1).cgColor,
                UIColor(red: 0.58, green: 0.45, blue: 0.57, alpha: 1).cgColor
            ] as CFArray
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors,
                locations: [0, 1]
            )!
            context.cgContext.drawLinearGradient(
                gradient,
                start: .zero,
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            func drawRidge(color: UIColor, baseY: CGFloat, peaks: [CGFloat]) {
                let width = size.width / CGFloat(peaks.count - 1)
                let path = UIBezierPath()
                path.move(to: CGPoint(x: 0, y: size.height))
                for (index, peak) in peaks.enumerated() {
                    path.addLine(to: CGPoint(x: CGFloat(index) * width, y: baseY - peak))
                }
                path.addLine(to: CGPoint(x: size.width, y: size.height))
                path.close()
                color.setFill()
                path.fill()
            }

            drawRidge(
                color: UIColor(red: 0.18, green: 0.17, blue: 0.35, alpha: 1),
                baseY: 730,
                peaks: [210, 120, 190, 140, 230, 150, 250, 160, 220, 145, 260, 180, 230]
            )
            drawRidge(
                color: UIColor(red: 0.11, green: 0.11, blue: 0.28, alpha: 1),
                baseY: 850,
                peaks: [160, 80, 220, 120, 260, 100, 310, 240, 180, 260, 130, 220, 170]
            )
            drawRidge(
                color: UIColor(red: 0.06, green: 0.06, blue: 0.18, alpha: 1),
                baseY: 1010,
                peaks: [120, 190, 155, 215, 140, 260, 335, 280, 180, 125, 210, 250, 150]
            )
        }
    }
}
