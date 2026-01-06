import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let skView = view as? SKView else { return }

        let scene = MenuScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        skView.presentScene(scene)

        skView.ignoresSiblingOrder = true
    }

    override var prefersStatusBarHidden: Bool {
        true
    }
}
