import SpriteKit

final class LevelSelectScene: SKScene {
    private let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private var levelLabels: [SKLabelNode] = []
    private let levelsCount = 10

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.94, green: 0.86, blue: 0.70, alpha: 1.0)

        titleLabel.text = "ВЫБОР УРОВНЯ"
        titleLabel.fontSize = min(size.width, size.height) * 0.08
        titleLabel.fontColor = SKColor(red: 0.18, green: 0.16, blue: 0.12, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.7)
        titleLabel.zPosition = 1
        addChild(titleLabel)

        createLevelButtons()
        layoutLevelButtons()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        titleLabel.fontSize = min(size.width, size.height) * 0.08
        titleLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.7)
        for label in levelLabels {
            label.fontSize = min(size.width, size.height) * 0.055
        }
        layoutLevelButtons()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        if let node = nodes.first(where: { $0.name?.hasPrefix("level_") == true }),
           let name = node.name,
           let level = Int(name.replacingOccurrences(of: "level_", with: "")) {
            let nextScene = GameScene(size: size, level: level)
            nextScene.scaleMode = scaleMode
            view?.presentScene(nextScene, transition: SKTransition.fade(withDuration: 0.25))
        }
    }

    private func createLevelButtons() {
        guard levelLabels.isEmpty else { return }
        for level in 1...levelsCount {
            let label = SKLabelNode(fontNamed: "Avenir-Heavy")
            label.text = "УРОВЕНЬ \(level)"
            label.fontSize = min(size.width, size.height) * 0.055
            label.fontColor = SKColor(red: 0.30, green: 0.26, blue: 0.18, alpha: 1.0)
            label.name = "level_\(level)"
            label.zPosition = 1
            levelLabels.append(label)
            addChild(label)
        }
    }

    private func layoutLevelButtons() {
        guard !levelLabels.isEmpty else { return }
        let columns = 2
        let rows = Int(ceil(Double(levelsCount) / Double(columns)))
        let usableWidth = size.width * 0.8
        let startX = size.width * 0.5 - usableWidth * 0.5
        let columnSpacing = usableWidth / CGFloat(columns - 1)
        let startY = size.height * 0.58
        let rowSpacing = min(size.height * 0.1, 70)

        for (index, label) in levelLabels.enumerated() {
            let row = index / columns
            let column = index % columns
            let x = startX + columnSpacing * CGFloat(column)
            let y = startY - rowSpacing * CGFloat(row)
            label.position = CGPoint(x: x, y: y)
        }
    }
}
