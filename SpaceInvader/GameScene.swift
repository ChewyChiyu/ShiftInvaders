//
//  GameScene.swift
//  SpaceInvader
//
//  Created by Evan Chen on 6/26/17.
//  Copyright © 2017 Evan Chen. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion


enum attackConfig{
    case formationAlpha, formationBeta, formationGamma
}

class GameScene: SKScene , SKPhysicsContactDelegate{
    //game screen var
    var spaceDefender : SKSpriteNode!
    var scoreLabel : SKLabelNode!
    //management of score to label screen
    var score = 0{
        didSet{
            scoreLabel.text = String(score)
        }
    }
    //core motion var
    let motionManager = CMMotionManager()
    
    
    //enemy var
    var enemyVector = CGVector(dx: 0, dy: -10)
    let maxEnemyVector = CGVector(dx: 0, dy: -30)
    
    
    
    var gameLevel = 0{
        didSet{
            
            if(gameLevel>=0){ //regular game
                
                //increase difficulity
                if(enemyVector.dy > maxEnemyVector.dy){
                    enemyVector.dy-=1
                }
                //for now switch all formation
                switch(Int(arc4random_uniform(3))){
                case 0:
                    loadEnemy(formation: attackConfig.formationAlpha)
                    break
                case 1:
                    loadEnemy(formation: attackConfig.formationBeta)
                    break
                case 2:
                    loadEnemy(formation: attackConfig.formationGamma)
                    break
                default:
                    break
                }
                
                
            }else if(gameLevel == -1){
                //game state == -1 die screen
                //prompting game over screen and hiding some objects
                
                //hiding screen items not needed
                scoreLabel.alpha = 0
                //showing menu
                let gameOverScene = SKScene(fileNamed: "MenuNode")
                let menuNode = gameOverScene?.childNode(withName: "Menu")
                let scoreNode = menuNode?.childNode(withName: "Score") as? SKLabelNode
                //managing scores . . . .
                scoreNode?.text = String(score)
                
                
                
                //adding fade
                menuNode?.removeFromParent()
                addChild(menuNode!)
                menuNode?.alpha = 0
                menuNode?.run(SKAction.fadeAlpha(to: 1, duration: 1.0), completion : {
                    //adding restart button prompt
                    let restart = menuNode?.childNode(withName: "Restart") as? RestartButton
                    restart?.playAction = {
                        //restarting game
                        let view = self.view
                        let scene = SKScene(fileNamed: "GameScene")
                        view?.ignoresSiblingOrder = true
                        scene?.scaleMode = .aspectFill
                        scene?.size = (view?.bounds.size)!
                        view?.presentScene(scene!, transition: SKTransition.fade(withDuration: 1))
                    }
                })
                
                
                
            }
            
            
        }
    }
    
    func loadEnemy(formation: attackConfig){
        
        var scene = SKScene()
        
        switch(formation){
        case attackConfig.formationAlpha:
            scene = SKScene(fileNamed: "formationAlpha")!
            break
            
        case attackConfig.formationBeta:
            scene = SKScene(fileNamed: "formationBeta")!
            break
        case attackConfig.formationGamma:
            scene = SKScene(fileNamed: "formationGamma")!
            break
        }
        
        for child in (scene.children){
            child.removeFromParent()
            addChild(child)
            child.physicsBody?.applyImpulse(enemyVector)
            
        }
        
        
    }
    
    
    
    override func didMove(to view: SKView) {
        
        
        //initial nodes to load
        spaceDefender = self.childNode(withName: "SpaceDefender") as? SKSpriteNode
        
        
        motionManager.startAccelerometerUpdates()
        
        
        scoreLabel = self.childNode(withName: "score") as? SKLabelNode
        
        
        physicsWorld.contactDelegate = self
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let A = contact.bodyA
        let B = contact.bodyB
        
        let nodeA = A.node
        let nodeB = B.node
        
        
        if(nodeA?.name=="invader" && nodeB?.name=="bullet" || nodeB?.name=="invader" && nodeA?.name=="bullet"){
            nodeA?.removeFromParent()
            nodeB?.removeFromParent()
            score+=10 //basic score increment for now
        }
        
        if(nodeA?.name=="invader" && nodeB?.name=="SpaceDefender" || nodeB?.name=="invader" && nodeA?.name=="SpaceDefender" && gameLevel != -1){
            //game over
            gameLevel = -1
            
        }
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameLevel==0){
            gameLevel+=1
        }
        if(gameLevel != -1){
            shoot()
        }
    }
    func shoot(){
        let bullet = Bullet()
        bullet.position = spaceDefender.position
        bullet.position.y += (spaceDefender.size.height*0.8)
        addChild(bullet)
        bullet.physicsBody?.applyImpulse(CGVector(dx:0,dy:2))
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        //only handel if not gameState -1
        if(gameLevel != -1){
            // Called before each frame is rendered
            
            //handle Accelerometer data
            handleAccel()
            //clear sprites
            clearSprites()
            //check if need to reload a level
            checkIfReload()
        }
    }
    func checkIfReload(){
        var count = 0
        for child in self.children{
            if(child.name == "invader"){
                count+=1
            }
        }
        if(count==0 && !(gameLevel <= 0)){ //start spawning in next wave when there are three or less enemys left
            gameLevel+=1
        }
    }
    func handleAccel(){
        if let data = motionManager.accelerometerData {
            if (data.acceleration.x > 0.2 && spaceDefender.position.x+spaceDefender.size.width/2 < (view?.bounds.width)!) {
                spaceDefender.physicsBody?.velocity.dx = 300
            }
            else if (data.acceleration.x < -0.2 && spaceDefender.position.x-spaceDefender.size.width/2 > 0 ) {
                spaceDefender.physicsBody?.velocity.dx = -300
            }
            else{
                spaceDefender.physicsBody?.velocity.dx = 0
            }
            
        }
        
    }
    func clearSprites(){
        for child in self.children{
            if(!intersects(child) && child.name == "bullet"){
                child.removeFromParent()
            }else if(child.name == "invader" && child.position.y < -100){ //give or take 100 pixels
                child.removeFromParent()
            }
        }
    }
    
    
}
