import SpriteKit

final class GameScene: SKScene {
    private enum TurnChoice {
        case left
        case right
    }

    private let playerSpeed: CGFloat = 160
    private let segmentLength: CGFloat = 300
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
    private let cameraNode = SKCameraNode()
    private let hintLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private let levelLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private let progressLabel = SKLabelNode(fontNamed: "Avenir-Heavy")
    private let finishNode = SKShapeNode(circleOfRadius: 14)

    private let level: Int
    private let requiredTurns: Int
    private var turnsMade = 0
    private var rngState: UInt64

    private var currentTarget: CGPoint?
    private var pathPoints: [CGPoint] = []
    private var segmentIndex = 0
    private var tappedForTurn = false
    private var currentSegmentStart: CGPoint?
    private var currentSegmentEnd: CGPoint?

    init(size: CGSize, level: Int) {
        self.level = max(1, level)
        self.requiredTurns = max(1, level * 2)
        self.rngState = UInt64(level) &* 6364136223846793005 &+ 1
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        self.level = 1
        self.requiredTurns = 2
        self.rngState = 1
        super.init(coder: aDecoder)
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.94, green: 0.86, blue: 0.70, alpha: 1.0)

        addChild(pathContainer)

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
        levelLabel.text = "Level \(level)"
        levelLabel.position = CGPoint(x: 0, y: 250)
        cameraNode.addChild(levelLabel)

        progressLabel.fontSize = 16
        progressLabel.fontColor = SKColor(red: 0.30, green: 0.26, blue: 0.18, alpha: 1.0)
        progressLabel.text = "Turns: \(turnsMade)/\(requiredTurns)"
        progressLabel.position = CGPoint(x: 0, y: 225)
        cameraNode.addChild(progressLabel)

        setupFinishNode()
        generatePath()
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
        guard !pathPoints.isEmpty, segmentIndex < pathPoints.count else { return }

        if segmentIndex == pathPoints.count - 1 {
            completeLevel()
            return
        }

        guard tappedForTurn else {
            resetLevel()
            return
        }

        tappedForTurn = false
        turnsMade += 1
        progressLabel.text = "Turns: \(turnsMade)/\(requiredTurns)"
        segmentIndex += 1
        currentTarget = pathPoints[segmentIndex]
        currentSegmentStart = pathPoints[segmentIndex - 1]
        currentSegmentEnd = currentTarget
    }

    private func generatePath() {
        pathContainer.removeAllChildren()
        setupFinishNode()
        pathPoints.removeAll(keepingCapacity: true)

        var points: [CGPoint] = []
        points.reserveCapacity(requiredTurns + 2)

        var currentPoint = CGPoint.zero
        points.append(currentPoint)

        var direction = CGVector(dx: 0, dy: 1)
        for _ in 0..<requiredTurns {
            currentPoint = CGPoint(x: currentPoint.x + direction.dx * segmentLength,
                                   y: currentPoint.y + direction.dy * segmentLength)
            points.append(currentPoint)
            direction = turn(direction: direction, choice: nextTurnChoice())
        }

        currentPoint = CGPoint(x: currentPoint.x + direction.dx * segmentLength,
                               y: currentPoint.y + direction.dy * segmentLength)
        points.append(currentPoint)

        pathPoints = points
        for index in 1..<points.count {
            drawPathSegment(from: points[index - 1], to: points[index])
        }

        placeFinishNode(at: points.last ?? .zero)

        segmentIndex = 1
        currentTarget = points[segmentIndex]
        currentSegmentStart = points[segmentIndex - 1]
        currentSegmentEnd = currentTarget
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
        currentTarget = nil
        currentSegmentStart = nil
        currentSegmentEnd = nil
        turnsMade = 0
        tappedForTurn = false
        hintLabel.text = "Tap to turn"
        progressLabel.text = "Turns: \(turnsMade)/\(requiredTurns)"
        player.position = .zero
        player.zRotation = 0
        cameraNode.position = CGPoint(x: player.position.x, y: player.position.y + 140)
        rngState = UInt64(level) &* 6364136223846793005 &+ 1
        generatePath()
    }

    private func completeLevel() {
        if level < 10 {
            let nextScene = GameScene(size: size, level: level + 1)
            nextScene.scaleMode = scaleMode
            view?.presentScene(nextScene, transition: SKTransition.fade(withDuration: 0.3))
        } else {
            let nextScene = LevelSelectScene(size: size)
            nextScene.scaleMode = scaleMode
            view?.presentScene(nextScene, transition: SKTransition.fade(withDuration: 0.3))
        }
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

    private func setupFinishNode() {
        finishNode.fillColor = SKColor(red: 0.35, green: 0.70, blue: 0.38, alpha: 1.0)
        finishNode.strokeColor = SKColor(red: 0.24, green: 0.52, blue: 0.28, alpha: 1.0)
        finishNode.lineWidth = 3
        finishNode.zPosition = 2
        if finishNode.parent == nil {
            pathContainer.addChild(finishNode)
        }
    }

    private func placeFinishNode(at point: CGPoint) {
        finishNode.position = point
    }

    private func nextTurnChoice() -> TurnChoice {
        rngState = rngState &* 6364136223846793005 &+ 1
        return ((rngState >> 63) == 0) ? .left : .right
    }

    private func turn(direction: CGVector, choice: TurnChoice) -> CGVector {
        switch choice {
        case .left:
            return CGVector(dx: -direction.dy, dy: direction.dx)
        case .right:
            return CGVector(dx: direction.dy, dy: -direction.dx)
        }
    }
}
