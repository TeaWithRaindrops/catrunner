import SpriteKit

final class GameScene: SKScene {
    private enum TurnChoice: String {
        case left = "LEFT"
        case right = "RIGHT"
    }

    private struct Fork {
        let forkPoint: CGPoint
        let leftEnd: CGPoint
        let rightEnd: CGPoint
    }

    private let playerSpeed: CGFloat = 160
    private let forkDistance: CGFloat = 300
    private let branchLength: CGFloat = 220
    private let branchOffset: CGFloat = 180
    private let arriveThreshold: CGFloat = 8

    private let player: SKSpriteNode = {
        let texture = SKTexture(imageNamed: "catrunner")
        let sprite = SKSpriteNode(texture: texture)
        let size = texture.size()
        if size.height > 0 {
            let targetHeight: CGFloat = 44
            sprite.setScale(targetHeight / size.height)
        } else {
            sprite.size = CGSize(width: 32, height: 32)
        }
        return sprite
    }()
    private let pathContainer = SKNode()
    private let cameraNode = SKCameraNode()
    private let hintLabel = SKLabelNode(fontNamed: "Avenir-Heavy")

    private var currentFork: Fork?
    private var currentTarget: CGPoint?
    private var currentOrigin = CGPoint.zero
    private var nextTurn: TurnChoice = .right

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.94, green: 0.86, blue: 0.70, alpha: 1.0)

        addChild(pathContainer)

        player.position = CGPoint(x: 0, y: 0)
        addChild(player)
        startIdleRunLoop()

        addChild(cameraNode)
        camera = cameraNode

        hintLabel.fontSize = 18
        hintLabel.fontColor = SKColor(red: 0.18, green: 0.16, blue: 0.12, alpha: 1.0)
        hintLabel.text = "Tap to turn: \(nextTurn.rawValue)"
        hintLabel.position = CGPoint(x: 0, y: 220)
        cameraNode.addChild(hintLabel)

        currentOrigin = player.position
        generateFork()
    }

    override func update(_ currentTime: TimeInterval) {
        guard let target = currentTarget else { return }

        let dt = 1.0 / 60.0
        let direction = CGVector(dx: target.x - player.position.x, dy: target.y - player.position.y)
        let distance = sqrt(direction.dx * direction.dx + direction.dy * direction.dy)

        if distance <= arriveThreshold {
            handleArrive(at: target)
            return
        }

        let step = min(playerSpeed * CGFloat(dt), distance)
        let nx = direction.dx / max(distance, 0.001)
        let ny = direction.dy / max(distance, 0.001)
        player.position = CGPoint(x: player.position.x + nx * step, y: player.position.y + ny * step)
        player.zRotation = atan2(ny, nx) - .pi / 2

        cameraNode.position = CGPoint(x: player.position.x, y: player.position.y + 140)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        nextTurn = (nextTurn == .left) ? .right : .left
        hintLabel.text = "Tap to turn: \(nextTurn.rawValue)"
    }

    private func handleArrive(at point: CGPoint) {
        if let fork = currentFork, point == fork.forkPoint {
            currentTarget = (nextTurn == .left) ? fork.leftEnd : fork.rightEnd
            return
        }

        if let fork = currentFork, (point == fork.leftEnd || point == fork.rightEnd) {
            currentOrigin = point
            currentFork = nil
            generateFork()
            return
        }
    }

    private func generateFork() {
        let forkPoint = CGPoint(x: currentOrigin.x, y: currentOrigin.y + forkDistance)
        let leftEnd = CGPoint(x: forkPoint.x - branchOffset, y: forkPoint.y + branchLength)
        let rightEnd = CGPoint(x: forkPoint.x + branchOffset, y: forkPoint.y + branchLength)

        let fork = Fork(forkPoint: forkPoint, leftEnd: leftEnd, rightEnd: rightEnd)
        currentFork = fork
        currentTarget = forkPoint

        drawPathSegment(from: currentOrigin, to: forkPoint)
        drawPathSegment(from: forkPoint, to: leftEnd)
        drawPathSegment(from: forkPoint, to: rightEnd)
    }

    private func drawPathSegment(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let node = SKShapeNode(path: path)
        node.strokeColor = SKColor(red: 0.80, green: 0.72, blue: 0.54, alpha: 1.0)
        node.lineWidth = 40
        node.lineCap = .round
        node.zPosition = -1
        pathContainer.addChild(node)

        let edge = SKShapeNode(path: path)
        edge.strokeColor = SKColor(red: 0.68, green: 0.60, blue: 0.45, alpha: 1.0)
        edge.lineWidth = 44
        edge.lineCap = .round
        edge.zPosition = -2
        pathContainer.addChild(edge)
    }

    private func startIdleRunLoop() {
        let bobUp = SKAction.moveBy(x: 0, y: 2.5, duration: 0.18)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = bobUp.reversed()
        let bob = SKAction.sequence([bobUp, bobDown])

        let squash = SKAction.scaleX(to: 1.04, y: 0.98, duration: 0.18)
        squash.timingMode = .easeInEaseOut
        let stretch = SKAction.scaleX(to: 0.98, y: 1.04, duration: 0.18)
        stretch.timingMode = .easeInEaseOut
        let pulse = SKAction.sequence([squash, stretch])

        let combined = SKAction.group([bob, pulse])
        player.run(SKAction.repeatForever(combined), withKey: "idleRunLoop")
    }
}
