//
//  GameScene.swift
//  HoppyBunny
//
//  Created by Timothy Liew on 6/22/16.
//  Copyright (c) 2016 Tim Liew. All rights reserved.
//

import SpriteKit
import AudioToolbox

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    enum GameSceneState{
        case Active, Gameover
    }
    
    var hero: SKSpriteNode!
    var sinceTouch: CFTimeInterval = 0
    var spawnTimer: CFTimeInterval = 0
    let fixedDelta: CFTimeInterval = 1.0/60.0 /* 60 FPS */
    let scrollSpeed: CGFloat = 160
    var scrollLayer: SKNode!
    var scrollCloud: SKNode!
    var obstacleLayer: SKNode!
    var restartButton: MSButtonNode! //UI Connection
    var gameState: GameSceneState = .Active
    var scoreLabel: SKLabelNode!
    var points = 0
    var highScore: SKLabelNode!
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        /* Recursive node search for 'hero' (child of referenced node) */
        hero = self.childNodeWithName("//hero") as! SKSpriteNode
        
        /* Set reference to scroll layer node */
        scrollLayer = self.childNodeWithName("scrollLayer")
        
        /* Set reference to obstacle layer node */
        obstacleLayer = self.childNodeWithName("obstacleLayer")
        
        /* Set reference to scroll cloud layer */
        scrollCloud = self.childNodeWithName("scrollCloud")
        
        /* Set reference to score label */
        scoreLabel = self.childNodeWithName("scoreLabel") as! SKLabelNode
        
        /* Reset score label */
        scoreLabel.text = String(points)
        
        /* Set reference to high score */
        highScore = self.childNodeWithName("highScore") as! SKLabelNode
        
        highScore.text = String(NSUserDefaults.standardUserDefaults().integerForKey("highScore"))
        
        /* Set physics contact delegate */
        physicsWorld.contactDelegate = self
        
        /* UI Connection */
        restartButton = self.childNodeWithName("buttonRestart") as! MSButtonNode
        
        /* Setup restart button selection handler */
        restartButton.selectedHandler = {
            
            /* Grab reference to our SpriteKit view */
            let skyView = self.view as SKView!
            
            /* Load game scene */
            let scene = GameScene(fileNamed: "GameScene")
            
            /* Ensure correct aspect mode */
            scene?.scaleMode = .AspectFill
            
            /* Restart game scene  */
            skyView.presentScene(scene)
        }
        
        restartButton.state = .Hidden
  
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if gameState != .Active{
            return
        }
        
        /* Reset velocity, helps improve response against cumulative falling velocity */
        hero.physicsBody?.velocity = CGVectorMake(0, 0)
        
        /* Called when a touch begins */
        
        /* Apply vertical impulse */
        hero.physicsBody?.applyImpulse(CGVectorMake(0, 300))
        
        /* Adding SFX */
        let flapSFX = SKAction.playSoundFileNamed("sfx_flap", waitForCompletion: false)
        self.runAction(flapSFX)
        
        /* Apply subtle rotation */
        hero.physicsBody?.applyAngularImpulse(1)
        
        /* Reset touch timer */
        sinceTouch = 0
        
        /*  */
    }
    
    override func update(currentTime: CFTimeInterval) {
        /* Skip any updates */
        if gameState != .Active {
            return
        }
        
        /* Called before each frame is rendered */
        
        /*Grab current velocity*/
        let velocityY = hero.physicsBody?.velocity.dy ?? 0
        
        /*Check and cap vertical velocity*/
        if velocityY > 400 {
            hero.physicsBody?.velocity.dy = 400
        }
        
        /*Apply falling rotation*/
        if sinceTouch > 0.1{
            let impulse = -2000 * fixedDelta
            hero.physicsBody?.applyAngularImpulse(CGFloat(impulse))
        }
        
        /* Clamp rotation */
        hero.zRotation.clamp(CGFloat(-20).degreesToRadians(),CGFloat(30).degreesToRadians())
        hero.physicsBody?.angularVelocity.clamp(-2, 2)
        
        /* Update last touch timer */
        sinceTouch+=fixedDelta
        
        scrollWorld()
        
        updateObstacles()
        
        spawnTimer+=fixedDelta
    }
    
    func scrollWorld(){
        /* Scroll World */
        scrollLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes*/
        for ground in scrollLayer.children as! [SKSpriteNode]{
            
            /* Get ground node position, convert node position to scene space*/
            let groundPosition = scrollLayer.convertPoint(ground.position, toNode: self)
            
            /* Check if ground sprite has left the scene */
            if groundPosition.x <= -ground.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPointMake((self.size.width / 2) + size.width, groundPosition.y)
                
                /* Convert new node position back to scroll layer space */
                ground.position = self.convertPoint(newPosition, toNode: scrollLayer)
            }
        }
        
        /* Scroll Cloud */
        scrollCloud.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through scroll layer nodes*/
        for cloud in scrollCloud.children as! [SKSpriteNode]{
            
            /* Get ground node position, convert node position to scene space*/
            let cloudPosition = scrollCloud.convertPoint(cloud.position, toNode: self)
            
            /* Check if ground sprite has left the scene */
            if cloudPosition.x <= -cloud.size.width / 2 {
                
                /* Reposition ground sprite to the second starting position */
                let newPosition = CGPointMake((self.size.width / 2) + size.width, cloudPosition.y)
                
                /* Convert new node position back to scroll layer space */
                cloud.position = self.convertPoint(newPosition, toNode: scrollCloud)
            }
        }

    }
    
    func updateObstacles(){
        /* Update Obstacles */
        obstacleLayer.position.x -= scrollSpeed * CGFloat(fixedDelta)
        
        /* Loop through obstacle layer nodes */
        for obstacle in obstacleLayer.children as! [SKReferenceNode]{
            
            /* Get obstacle node position, convert node position to scene space */
            let obstaclePosition = obstacleLayer.convertPoint(obstacle.position, toNode: self)
            
            /* Check if the bunny has left the scene */
            if obstaclePosition.x <= 0{
                
                /* Remove obstacle node from obstacle layer */
                obstacle.removeFromParent()
            }
        }
        /* Time to add new obstacle */
        if spawnTimer >= 1.5{
            /* Create a new obstacle reference object using our obstacle resource */
            let resourcePath = NSBundle.mainBundle().pathForResource("Obstacles", ofType: "sks")
            let newObstacle = SKReferenceNode (URL: NSURL (fileURLWithPath: resourcePath!))
            obstacleLayer.addChild(newObstacle)
            
            /* Generate new obstacle position, start just outside screen and with a random y value */
            let randomPosition = CGPointMake(352, CGFloat.random(min: 234, max: 382))
            
            /* Convert new node position back to obstacle layer space */
            newObstacle.position = self.convertPoint(randomPosition, toNode: obstacleLayer)
            
            /* Reset spawn timer */
            spawnTimer = 0
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        /* Ensure only called while game running */
        if gameState != .Active { return }
        
        /* Get references to bodies involved in collision */
        let contactA: SKPhysicsBody = contact.bodyA
        let contactB: SKPhysicsBody = contact.bodyB
        
        /* Get references to the physics body parent nodes */
        let nodeA = contactA.node!
        let nodeB = contactB.node!
        
        /* Did our body pass through the goal? */
        if nodeA.name == "goal" || nodeB.name == "goal"{
            points += 1
            
            scoreLabel.text = String(points)
            
            if points > Int(highScore.text!) {
                highScore.text = String(points)
            }
            
            return

        }
        
        if points > NSUserDefaults.standardUserDefaults().integerForKey("highScore") {
            NSUserDefaults.standardUserDefaults().setInteger(points, forKey: "highScore")
            NSUserDefaults.standardUserDefaults().synchronize()
        }
        
        highScore.text = String(NSUserDefaults.standardUserDefaults().integerForKey("highScore"))

        
        /* Hero touches anything, game over */
        
        /* Change game state to game over */
        gameState = .Gameover
        
        /* Stop any new angular velocity being applied */
        hero.physicsBody?.allowsRotation = false
        
        /* Reset angular velocity */
        hero.physicsBody?.angularVelocity = 0
        
        /* Stop hero flapping animation */
        hero.removeAllActions()
        
        /* Create our hero death action */
        let heroDeath = SKAction.runBlock({
            
            /* Put our hero face down in the dirt */
            self.hero.zRotation = CGFloat(-90).degreesToRadians()
            
            /* Stop hero from colliding with anything else */
            self.hero.physicsBody?.collisionBitMask = 0
        })
        
        
        /* Run action */
        hero.runAction(heroDeath)
        
        /* Load the shake action resource*/
        let shakeScene:SKAction = SKAction.init(named: "Shake")!
        
        /* Loop through all the nodes */
        for node in self.children{
            /* Apply action on each ground node*/
            node.runAction(shakeScene)
        }
        
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    
        /* Show restart button */
        restartButton.state = .Active
        
        
    }
    
    
    
}
