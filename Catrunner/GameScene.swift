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
    private let arriveThreshold: CGFloat = 8
    private let pathWidth: CGFloat = 40
    private let offPathMargin: CGFloat = 6

    private lazy var runFrames: [SKTexture] = makeRunFrames()
    private let runFrameDuration: TimeInterval = 0.12

    private lazy var player: SKSpriteNode = {
        let texture = runFrames.first ?? SKTexture(imageNamed: "catrunner")
        let sprite = SKSpriteNode(texture: texture)
        return sprite
    }()
    private let pathContainer = SKNode()
    private let arrowContainer = SKNode()
    private let cameraNode = SKCameraNode()
    private let hintLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private let levelLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private let progressLabel = SKLabelNode(fontNamed: "Avenir-Heavy")

    private let level: Int
    private let requiredTurns: Int
    private var turnsMade = 0
    private var finishAfterSegment = false

    private var currentFork: Fork?
    private var currentTarget: CGPoint?
    private var currentOrigin = CGPoint.zero
    private var requiredTurn: TurnChoice = .right
    private var tappedForTurn = false
    private var turnArrow: SKShapeNode?
    private var currentSegmentStart: CGPoint?
    private var currentSegmentEnd: CGPoint?

    init(size: CGSize, level: Int) {
        self.level = max(1, level)
        self.requiredTurns = max(1, level)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        self.level = 1
        self.requiredTurns = 1
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.94, green: 0.86, blue: 0.70, alpha: 1.0)

        addChild(pathContainer)
        addChild(arrowContainer)

        player.position = CGPoint(x: 0, y: 0)
        addChild(player)
        updatePlayerScale()
        startRunAnimation()

        addChild(cameraNode)
        camera = cameraNode

        hintLabel.fontSize = 18
        hintLabel.fontColor = SKColor(red: 0.18, green: 0.16, blue: 0.12, alpha: 1.0)
        hintLabel.text = "Tap to turn"
        hintLabel.position = CGPoint(x: 0, y: 200)
        cameraNode.addChild(hintLabel)

        levelLabel.fontSize = 18
        levelLabel.fontColor = SKColor(red: 0.18, green: 0.16, blue: 0.12, alpha: 1.0)
        levelLabel.text = "Уровень \(level)"
        levelLabel.position = CGPoint(x: 0, y: 250)
        cameraNode.addChild(levelLabel)

        progressLabel.fontSize = 16
        progressLabel.fontColor = SKColor(red: 0.30, green: 0.26, blue: 0.18, alpha: 1.0)
        progressLabel.text = "Повороты: \(turnsMade)/\(requiredTurns)"
        progressLabel.position = CGPoint(x: 0, y: 225)
        cameraNode.addChild(progressLabel)

        currentOrigin = player.position
        generateFork()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updatePlayerScale()
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
        checkOffPath()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        tappedForTurn = true
    }

    private func handleArrive(at point: CGPoint) {
        if let fork = currentFork, point == fork.forkPoint {
            guard tappedForTurn else {
                resetLevel()
                return
            }
            turnsMade += 1
            progressLabel.text = "Повороты: \(turnsMade)/\(requiredTurns)"
            currentTarget = (requiredTurn == .left) ? fork.leftEnd : fork.rightEnd
            currentSegmentStart = fork.forkPoint
            currentSegmentEnd = currentTarget
            if turnsMade >= requiredTurns {
                finishAfterSegment = true
            }
            tappedForTurn = false
            return
        }

        if let fork = currentFork, (point == fork.leftEnd || point == fork.rightEnd) {
            currentOrigin = point
            currentFork = nil
            if finishAfterSegment {
                completeLevel()
            } else {
                generateFork()
            }
            return
        }
    }

    private func generateFork() {
        let forkPoint = CGPoint(x: currentOrigin.x, y: currentOrigin.y + forkDistance)
        let leftEnd = CGPoint(x: forkPoint.x - branchLength, y: forkPoint.y)
        let rightEnd = CGPoint(x: forkPoint.x + branchLength, y: forkPoint.y)

        let fork = Fork(forkPoint: forkPoint, leftEnd: leftEnd, rightEnd: rightEnd)
        currentFork = fork
        currentTarget = forkPoint
        currentSegmentStart = currentOrigin
        currentSegmentEnd = forkPoint
        finishAfterSegment = false
        tappedForTurn = false
        requiredTurn = Bool.random() ? .left : .right

        drawPathSegment(from: currentOrigin, to: forkPoint)
        drawPathSegment(from: forkPoint, to: leftEnd)
        drawPathSegment(from: forkPoint, to: rightEnd)
        placeTurnArrow(for: fork)
    }

    private func drawPathSegment(from start: CGPoint, to end: CGPoint) {
        let path = CGMutablePath()
        path.move(to: start)
        path.addLine(to: end)

        let node = SKShapeNode(path: path)
        node.strokeColor = SKColor(red: 0.80, green: 0.72, blue: 0.54, alpha: 1.0)
        node.lineWidth = pathWidth
        node.lineCap = .round
        node.zPosition = -1
        pathContainer.addChild(node)

        let edge = SKShapeNode(path: path)
        edge.strokeColor = SKColor(red: 0.68, green: 0.60, blue: 0.45, alpha: 1.0)
        edge.lineWidth = pathWidth + 4
        edge.lineCap = .round
        edge.zPosition = -2
        pathContainer.addChild(edge)
    }

    private func placeTurnArrow(for fork: Fork) {
        arrowContainer.removeAllChildren()

        let direction: CGVector
        let point: CGPoint

        if requiredTurn == .left {
            direction = CGVector(dx: fork.leftEnd.x - fork.forkPoint.x, dy: fork.leftEnd.y - fork.forkPoint.y)
            point = CGPoint(x: fork.forkPoint.x + direction.dx * 0.35, y: fork.forkPoint.y + direction.dy * 0.35)
        } else {
            direction = CGVector(dx: fork.rightEnd.x - fork.forkPoint.x, dy: fork.rightEnd.y - fork.forkPoint.y)
            point = CGPoint(x: fork.forkPoint.x + direction.dx * 0.35, y: fork.forkPoint.y + direction.dy * 0.35)
        }

        turnArrow = makeArrowNode()
        if let turnArrow {
            turnArrow.position = point
            turnArrow.zRotation = atan2(direction.dy, direction.dx) - .pi / 2
            arrowContainer.addChild(turnArrow)
        }
    }

    private func makeArrowNode() -> SKShapeNode {
        let size: CGFloat = 18
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: size))
        path.addLine(to: CGPoint(x: -size * 0.55, y: -size * 0.4))
        path.addLine(to: CGPoint(x: size * 0.55, y: -size * 0.4))
        path.closeSubpath()

        let arrow = SKShapeNode(path: path)
        arrow.fillColor = SKColor(red: 0.30, green: 0.26, blue: 0.18, alpha: 1.0)
        arrow.strokeColor = SKColor(red: 0.20, green: 0.18, blue: 0.12, alpha: 1.0)
        arrow.lineWidth = 2
        arrow.zPosition = 1
        return arrow
    }

    private func makeRunFrames() -> [SKTexture] {
        let names = ["catrunner1", "catrunner2", "catrunner3", "catrunner4"]
        return names.map { SKTexture(imageNamed: $0) }
    }

    private func checkOffPath() {
        guard let start = currentSegmentStart, let end = currentSegmentEnd else { return }
        let distance = distanceFromPoint(player.position, toSegmentStart: start, end: end)
        let allowed = (pathWidth * 0.5) + offPathMargin
        if distance > allowed {
            resetLevel()
        }
    }

    private func distanceFromPoint(_ point: CGPoint, toSegmentStart start: CGPoint, end: CGPoint) -> CGFloat {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy
        if lengthSquared == 0 {
            let vx = point.x - start.x
            let vy = point.y - start.y
            return sqrt(vx * vx + vy * vy)
        }

        let t = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared))
        let projX = start.x + t * dx
        let projY = start.y + t * dy
        let vx = point.x - projX
        let vy = point.y - projY
        return sqrt(vx * vx + vy * vy)
    }

    private func resetLevel() {
        pathContainer.removeAllChildren()
        arrowContainer.removeAllChildren()
        currentFork = nil
        currentTarget = nil
        currentOrigin = .zero
        currentSegmentStart = nil
        currentSegmentEnd = nil
        turnsMade = 0
        finishAfterSegment = false
        tappedForTurn = false
        hintLabel.text = "Tap to turn"
        progressLabel.text = "Повороты: \(turnsMade)/\(requiredTurns)"
        player.position = .zero
        player.zRotation = 0
        cameraNode.position = CGPoint(x: player.position.x, y: player.position.y + 140)
        generateFork()
    }

    private func completeLevel() {
        let nextScene = LevelSelectScene(size: size)
        nextScene.scaleMode = scaleMode
        view?.presentScene(nextScene, transition: SKTransition.fade(withDuration: 0.3))
    }

    private func updatePlayerScale() {
        guard let texture = player.texture else { return }
        let size = texture.size()
        guard size.height > 0 else {
            player.size = CGSize(width: 32, height: 32)
            return
        }
        let targetHeight = self.size.height * 0.05
        player.setScale(targetHeight / size.height)
    }

    private func startRunAnimation() {
        guard !runFrames.isEmpty else { return }
        let action = SKAction.animate(with: runFrames, timePerFrame: runFrameDuration, resize: false, restore: false)
        player.run(SKAction.repeatForever(action), withKey: "runLoop")
    }
}
