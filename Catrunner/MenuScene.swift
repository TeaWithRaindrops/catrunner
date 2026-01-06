import SpriteKit

final class MenuScene: SKScene {
    private let titleLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private let startLabel = SKLabelNode(fontNamed: "Avenir-Heavy")

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.94, green: 0.86, blue: 0.70, alpha: 1.0)

        titleLabel.text = "CATRUNNER"
        titleLabel.fontSize = min(size.width, size.height) * 0.12
        titleLabel.fontColor = SKColor(red: 0.18, green: 0.16, blue: 0.12, alpha: 1.0)
        titleLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.62)
        titleLabel.zPosition = 1
        addChild(titleLabel)

        startLabel.text = "НАЧАТЬ ИГРУ"
        startLabel.fontSize = min(size.width, size.height) * 0.06
        startLabel.fontColor = SKColor(red: 0.30, green: 0.26, blue: 0.18, alpha: 1.0)
        startLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.38)
        startLabel.name = "start"
        startLabel.zPosition = 1
        addChild(startLabel)

        let pulseUp = SKAction.scale(to: 1.05, duration: 0.6)
        pulseUp.timingMode = .easeInEaseOut
        let pulseDown = SKAction.scale(to: 1.0, duration: 0.6)
        pulseDown.timingMode = .easeInEaseOut
        startLabel.run(SKAction.repeatForever(SKAction.sequence([pulseUp, pulseDown])))
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        titleLabel.fontSize = min(size.width, size.height) * 0.12
        titleLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.62)
        startLabel.fontSize = min(size.width, size.height) * 0.06
        startLabel.position = CGPoint(x: size.width * 0.5, y: size.height * 0.38)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)
        if nodes.contains(where: { $0.name == "start" }) {
            let nextScene = LevelSelectScene(size: size)
            nextScene.scaleMode = scaleMode
            view?.presentScene(nextScene, transition: SKTransition.fade(withDuration: 0.25))
        }
    }
}
