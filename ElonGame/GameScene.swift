//
//  GameScene.swift
//  ElonGame
//
//  Created by Leonard Chen on 8/3/19.
//  Copyright © 2019 Leonard Chan. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation

class GameScene: SKScene {
    
    // Nodes
    var player: SKNode?
    var joystick: SKNode?
    var joystickKnob: SKNode?
    var cameraNode: SKCameraNode?
    var mountains1: SKNode?
    var mountains2: SKNode?
    var mountains3: SKNode?
    var moon: SKNode?
    var stars: SKNode?

    // Boolean
    var isJoystickMovable = false
    var rewardIsNotTouched = true
    var isHit = false
    
    // Measure
    var knobRadius: CGFloat = 50.0
    
    // Score
    let scoreLabel = SKLabelNode()
    var score = 0
    
    // Hearts
    var heartsArray = [SKSpriteNode]()
    let heartContainer = SKSpriteNode()
    
    // Sprite Engine
    var previousTimeInterval: TimeInterval = 0
    var isPlayerFacingRight = true
    let playerSpeed = 4.0
    
    // Player State Machine
    var playerStateMachine: GKStateMachine!
    
    // didMove
    override func didMove(to view: SKView) {
        
        physicsWorld.contactDelegate = self

        player = childNode(withName: "player")
        joystick = childNode(withName: "joystick")
        joystickKnob = joystick?.childNode(withName: "knob")
        cameraNode = childNode(withName: "cameraNode") as? SKCameraNode
        mountains1 = childNode(withName: "mountains1")
        mountains2 = childNode(withName: "mountains2")
        mountains3 = childNode(withName: "mountains3")
        moon = childNode(withName: "moon")
        stars = childNode(withName: "stars")
        
        playerStateMachine = GKStateMachine(states: [
            JumpingState(playerNode: player!),
            WalkingState(playerNode: player!),
            IdleState(playerNode: player!),
            LandingState(playerNode: player!),
            StunnedState(playerNode: player!)
        ])
        
        playerStateMachine.enter(IdleState.self)
        
        // Hearts
        heartContainer.position = CGPoint(x: -300, y: 140)
        heartContainer.zPosition = 5
        cameraNode?.addChild(heartContainer)
        fillHearts(count: 3)
        
        // Timer
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
            self.spawnMeteor()
        }
        
        scoreLabel.position = CGPoint(x: (cameraNode?.position.x)! + 310, y: 140)
        scoreLabel.fontColor = #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1)
        scoreLabel.fontSize = 24
        scoreLabel.fontName = "AvenirNext-Bold"
        scoreLabel.horizontalAlignmentMode = .right
        scoreLabel.text = String(score)
        cameraNode?.addChild(scoreLabel)
    }
}

// MARK: - Touches
extension GameScene {
    // Touch Began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            if let joystickKnob = joystickKnob {
                let location = touch.location(in: joystick!)
                isJoystickMovable = joystickKnob.frame.contains(location)
            }
            
            let location = touch.location(in: self)
            if !(joystick!.contains(location)) {
                playerStateMachine.enter(JumpingState.self)
                
                Audio.sharedInstance.playSound(soundFileName: Sound.jump.fileName)
            }
        }
    }
    
    // Touch Moved
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let joystick = joystick else { return }
        guard let joystickKnob = joystickKnob else { return }
        
        if !isJoystickMovable { return }
        
        // Distance
        for touch in touches {
            let position = touch.location(in: joystick)
            let length = sqrt(pow(position.y, 2) + pow(position.x, 2))
            let angle = atan2(position.y, position.x)
            
            if knobRadius > length {
                joystickKnob.position = position
            } else {
                joystickKnob.position = CGPoint(x: cos(angle) * knobRadius, y: sin(angle) * knobRadius)
            }
        }
    }
    
    // Touch Ended
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let xJoystickjCoordinate = touch.location(in: joystick!).x
            let xLimit: CGFloat = 200.0
            if xJoystickjCoordinate > -xLimit && xJoystickjCoordinate < xLimit {
                resetKbobPosition()
            }
        }
    }
}

// MARK: - Action
extension GameScene {
    func resetKbobPosition() {
        let initialPoint = CGPoint(x: 0, y: 0)
        let moveBackAction = SKAction.move(to: initialPoint, duration: 0.1)
        moveBackAction.timingMode = .linear
        joystickKnob?.run(moveBackAction)
        isJoystickMovable = false
    }
    
    func rewardTouch() {
        score += 1
        scoreLabel.text = String(score)
    }
    
    func fillHearts(count: Int) {
        for index in 1...count {
            let heart = SKSpriteNode(imageNamed: "heart")
            let xPosition = heart.size.width * CGFloat(index - 1)
            heart.position = CGPoint(x: xPosition, y: 0)
            heartsArray.append(heart)
            heartContainer.addChild(heart)
        }
    }
    
    func loseHeart() {
        if isHit {
            let lastElementIndex = heartsArray.count - 1
            if heartsArray.indices.contains(lastElementIndex - 1) {
                let lastHeart = heartsArray[lastElementIndex]
                lastHeart.removeFromParent()
                heartsArray.remove(at: lastElementIndex)
                Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (timer) in
                    self.isHit = false
                }
            } else {
                dying()
                showDieScene()
            }
            
            invincible()
        }
    }
    
    func invincible() {
        player?.physicsBody?.categoryBitMask = 0
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { (timer) in
            self.player?.physicsBody?.categoryBitMask = 2
        }
    }
    
    func dying() {
        let dieAction = SKAction.move(to: CGPoint(x: -300, y: 0), duration: 0.1)
        player?.run(dieAction)
        removeAllActions()
        fillHearts(count: 3)
    }
    
    func showDieScene() {
        let gameOverScene = GameScene(fileNamed: "GameOver")
        view?.presentScene(gameOverScene)
    }
}

// MARK: - Game Loop
extension GameScene {
    override func update(_ currentTime: TimeInterval) {
        let deltaTime = currentTime - previousTimeInterval
        previousTimeInterval = currentTime
        
        rewardIsNotTouched = true
        
        // Camera
        cameraNode?.position.x = player!.position.x
        joystick?.position.y = (cameraNode?.position.y)! - 100
        joystick?.position.x = (cameraNode?.position.x)! - 300
        
        // Player movement
        guard let joystickKnob = joystickKnob else { return }
        let xPosition = Double(joystickKnob.position.x)
        
        let positivePosition = xPosition < 0 ? -xPosition : xPosition
        
        if floor(positivePosition) != 0 {
            playerStateMachine.enter(WalkingState.self)
        } else {
            playerStateMachine.enter(IdleState.self)
        }
        
        let displacement = CGVector(dx: deltaTime * xPosition * playerSpeed, dy: 0)
        
        let moveAction = SKAction.move(by: displacement, duration: 0)
        let faceAction: SKAction!
        
        let isMovingRight = xPosition > 0
        let isMovingLeft = xPosition < 0
        
        if isMovingLeft && isPlayerFacingRight {
            isPlayerFacingRight = false
            let faceMovement = SKAction.scaleX(to: -1, duration: 0.0)
            faceAction = SKAction.sequence([moveAction, faceMovement])
        } else if isMovingRight && !isPlayerFacingRight {
            isPlayerFacingRight = true
            let faceMovement = SKAction.scaleX(to: 1, duration: 0.0)
            faceAction = SKAction.sequence([moveAction, faceMovement])
        } else {
            faceAction = moveAction
        }
        player?.run(faceAction)
        
        // Background Parallax
        
        let parallax1 = SKAction.moveTo(x: (player?.position.x)!/(-10), duration: 0)
        mountains1?.run(parallax1)
        
        let parallax2 = SKAction.moveTo(x: (player?.position.x)!/(-20), duration: 0)
        mountains2?.run(parallax2)
        
        let parallax3 = SKAction.moveTo(x: (player?.position.x)!/(-40), duration: 0)
        mountains3?.run(parallax3)
        
        let parallax4 = SKAction.moveTo(x: (cameraNode?.position.x)!, duration: 0)
        moon?.run(parallax4)
        stars?.run(parallax4)
    }
}

// MARK: - Collision
extension GameScene: SKPhysicsContactDelegate {
    struct Collision {
        enum Masks: Int {
            case killing, player, reward, ground
            
            var bitmask: UInt32 {
                return 1 << self.rawValue
            }
        }
        
        let masks: (first: UInt32, second: UInt32)
        
        func matches(_ first: Masks, _ second: Masks) -> Bool {
            return (first.bitmask == masks.first && second.bitmask == masks.second) || (first.bitmask == masks.second && second.bitmask == masks.first)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = Collision(masks: (first: contact.bodyA.categoryBitMask, second: contact.bodyB.categoryBitMask))
        
        if collision.matches(.player, .killing) {
            loseHeart()
            isHit = true

            Audio.sharedInstance.playSound(soundFileName: Sound.hit.fileName)
            
            playerStateMachine.enter(StunnedState.self)
        }
        
        if collision.matches(.player, .ground) {
            playerStateMachine.enter(LandingState.self)
        }
        
        if collision.matches(.player, .reward) {
            if contact.bodyA.node?.name == "jewel" {
                contact.bodyA.node?.physicsBody?.categoryBitMask = 0
                contact.bodyA.node?.removeFromParent()
            } else if contact.bodyB.node?.name == "jewel" {
                contact.bodyB.node?.physicsBody?.categoryBitMask = 0
                contact.bodyB.node?.removeFromParent()
            }

            if rewardIsNotTouched {
                rewardTouch()
                rewardIsNotTouched = false
            }
            
            Audio.sharedInstance.playSound(soundFileName: Sound.reward.fileName)
            
        }
        
        if collision.matches(.ground, .killing) {
            if contact.bodyA.node?.name == "Meteor", let meteor = contact.bodyA.node {
                createMolten(at: meteor.position)
                meteor.removeFromParent()
            }
            
            if contact.bodyB.node?.name == "Meteor", let meteor = contact.bodyB.node {
                createMolten(at: meteor.position)
                meteor.removeFromParent()
            }
            
            Audio.sharedInstance.playSound(soundFileName: Sound.meteorFalling.fileName)
        }
        
        
    }
}

// MARK: - Meteor
extension GameScene {
    func spawnMeteor() {
        let node = SKSpriteNode(imageNamed: "meteor")
        node.name = "Meteor"
        
        let randomXPosition = Int(arc4random_uniform(UInt32(self.size.width)))
        
        node.position = CGPoint(x: randomXPosition, y: 270)
        node.anchorPoint = CGPoint(x: 0.5, y: 1)
        node.zPosition = 5
        
        let physicsBody = SKPhysicsBody(circleOfRadius: 30)
        node.physicsBody = physicsBody
        
        physicsBody.categoryBitMask = Collision.Masks.killing.bitmask
        physicsBody.collisionBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        physicsBody.contactTestBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        physicsBody.fieldBitMask = Collision.Masks.player.bitmask | Collision.Masks.ground.bitmask
        
        physicsBody.affectedByGravity = true
        physicsBody.allowsRotation = false
        physicsBody.restitution = 0.2
        physicsBody.friction = 10
        
        addChild(node)
    }
    
    func createMolten(at position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "molten")
        node.position.x = position.x
        node.position.y = position.y - 110
        node.zPosition = 4
        
        addChild(node)
        
        let action = SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.2),
            SKAction.removeFromParent()
        ])
        
        node.run(action)
    }
}
