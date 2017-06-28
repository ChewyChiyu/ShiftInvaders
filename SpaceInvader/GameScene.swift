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
import Firebase
import FirebaseDatabase
import FirebaseCore

enum attackConfig{
    case formationAlpha, formationBeta, formationGamma, formationDelta
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
    var nameVar = String("Evan") // string for now , user can change later
    //highscore handle
    
    var firstPlace: Int?
    var secondPlace: Int?
    var thirdPlace: Int?
    
    var firstName: String?
    var secondName: String?
    var thirdName: String?
    
    
    //firebase master branch
    
    let masterBranch = Database.database().reference()
    
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
                switch(Int(arc4random_uniform(4))){
                case 0:
                    loadEnemy(formation: attackConfig.formationAlpha)
                    break
                case 1:
                    loadEnemy(formation: attackConfig.formationBeta)
                    break
                case 2:
                    loadEnemy(formation: attackConfig.formationGamma)
                    break
                case 3:
                    loadEnemy(formation: attackConfig.formationDelta)
                    break
                default:
                    break
                }
                
                
            }else if(gameLevel == -1){
                //game state == -1 die screen
                //prompting game over screen and hiding some objects
                
                //hiding screen items not needed
                scoreLabel.alpha = 0
                self.physicsWorld.speed = 0
                //showing menu
                let gameOverScene = SKScene(fileNamed: "MenuNode")
                let menuNode = gameOverScene?.childNode(withName: "Menu")
                let scoreNode = menuNode?.childNode(withName: "Score") as? SKLabelNode
                //managing scores . . . .
                scoreNode?.text = String(score)
                //manage highscores
                if let s = UserDefaults.standard.value(forKey: "highscore") {
                    if(score > (s as? Int)!){
                        UserDefaults.standard.set(score, forKey: "highscore")
                    }
                } else {
                    //user default does not exist yet so set highscore to 0
                    UserDefaults.standard.set(score, forKey: "highscore")
                    
                }
                
                let highscoreNode = menuNode?.childNode(withName: "HighScore") as? SKLabelNode
                let highscore = (UserDefaults.standard.value(forKey: "highscore") as? Int)!
                highscoreNode?.text = String(highscore)
                
                
                //Will be handling firebase highscore over here
                //first seek if user is connected or not
                var isConnected:Bool = true
                let connectedRef = Database.database().reference(withPath: ".info/connected")
                connectedRef.observe(.value, with: { (connected) in
                    if let boolean = connected.value as? Bool, boolean == true {
                        print("connected")
                        isConnected = true
                        
                    } else {
                        print("disconnected")
                        isConnected = false
                    }
                })
                if(isConnected){ //only follow through if connected
                    fetchData {
                        //loop to here after downloading highscores
                        
                        
                        //per prompt highscore labels and such if score is thirdplace or better
                        self.fetchName{
                            
                            if(self.score>self.firstPlace!){
                                //name placement and score placement
                                self.thirdPlace = (self.secondPlace)
                                self.secondPlace = (self.firstPlace)
                                self.firstPlace  = (self.score)
                                
                                self.thirdName = (self.secondName)
                                self.secondName = (self.firstName)
                                self.firstName  = (self.nameVar!)
                                
                                
                            }else if(self.score>self.secondPlace!){
                                self.thirdPlace = (self.secondPlace)
                                self.secondPlace = (self.score)
                                
                                self.thirdName = (self.secondName)
                                self.secondName = (self.nameVar!)
                            }else if(self.score>self.thirdPlace!){
                                self.thirdName = (self.nameVar!)
                                self.thirdPlace = (self.score)
                                
                            }else{
                                //did not make it to highscore board
                                //hide new highscore label
                            }
                            
                            
                            // from database to screen labels
                            let firstLabel = menuNode?.childNode(withName: "First") as? SKLabelNode
                            let secondLabel = menuNode?.childNode(withName: "Second") as? SKLabelNode
                            let thirdLabel = menuNode?.childNode(withName: "Third") as? SKLabelNode
                            
                            
                            firstLabel?.text =  "\(self.firstName!) \(self.firstPlace!)"
                            secondLabel?.text = "\(self.secondName!) \(self.secondPlace!)"
                            thirdLabel?.text = "\(self.thirdName!) \(self.thirdPlace!)"
                            
                            
                            //upload new scores and names to database
                            self.masterBranch.child("First/score").setValue(self.firstPlace)
                            self.masterBranch.child("Second/score").setValue(self.secondPlace)
                            self.masterBranch.child("Third/score").setValue(self.thirdPlace)
                            
                            self.masterBranch.child("First/name").setValue(self.firstName)
                            self.masterBranch.child("Second/name").setValue(self.secondName)
                            self.masterBranch.child("Third/name").setValue(self.thirdName)
                            
                        }
                        
                    }
                    
                }
                
                
                
                
                
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
    func fetchData(andOnCompletion completion:@escaping ()->()){
        masterBranch.observeSingleEvent(of: .value, with: { snapshot in
            if(self.firstPlace==nil||self.secondPlace==nil||self.thirdPlace==nil||self.firstName==nil||self.secondName==nil||self.thirdName==nil){
                self.firstPlace = snapshot.childSnapshot(forPath: "First/score").value as? Int
                self.secondPlace = snapshot.childSnapshot(forPath: "Second/score").value as? Int
                self.thirdPlace = snapshot.childSnapshot(forPath: "Third/score").value as? Int
                
                self.firstName = snapshot.childSnapshot(forPath: "First/name").value as? String
                self.secondName = snapshot.childSnapshot(forPath: "Second/name").value as? String
                self.thirdName = snapshot.childSnapshot(forPath: "Third/name").value as? String
                
                completion()
            }
        })
    }
    func fetchName(andOnCompletion completion:@escaping ()->()){
        //getting name of user
        if(self.score > self.thirdPlace!){
            let alert = UIAlertController(title: "New Highscore!", message: "Enter a name", preferredStyle: .alert)
            
            alert.addTextField(configurationHandler: { (textField) -> Void in
                textField.text = ""
            })
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                let textField = alert.textFields![0]
                self.nameVar? = textField.text!
                completion()
            }))
            self.view?.window?.rootViewController?.present(alert, animated: true, completion: nil)
        }else{
            completion()
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
        case attackConfig.formationDelta:
            scene = SKScene(fileNamed: "formationDelta")!
            break
        }
        
        for child in (scene.children){
            child.removeFromParent()
            addChild(child)
            child.physicsBody?.collisionBitMask = 0 //pass through because im not changing all those values in editor
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
        
        
        
        
        
        //bullet velocity y positive, player shot, negative y velocity, invader shot
        
        if(nodeA?.name=="bullet" && nodeB?.name=="invader"){
            //bullet velocity negative so invader bullets do not kill themselves
            if((nodeA?.physicsBody?.velocity.dy)! > CGFloat(0)){
                //player shot bullet
                //adding partical effect for hit
                let spark = SKEmitterNode(fileNamed: "Spark")
                spark?.position = (nodeA?.position)!
                addChild(spark!)
                spark!.run(SKAction.applyTorque(10, duration: 0.5), completion: {
                    spark?.removeFromParent() //parical removal after finished animation
                })
                
                nodeA?.removeFromParent()
                nodeB?.removeFromParent()
                score+=10 //basic score increment for now
                
            }
            
        }
        if(nodeB?.name=="bullet" && nodeA?.name=="invader"){
            //bullet velocity negative so invader bullets do not kill themselves
            if((nodeB?.physicsBody?.velocity.dy)! > CGFloat(0)){
                //player shot bullet
                //adding partical effect for hit
                let spark = SKEmitterNode(fileNamed: "Spark")
                spark?.position = (nodeB?.position)!
                addChild(spark!)
                spark!.run(SKAction.applyTorque(10, duration: 0.5), completion: {
                    spark?.removeFromParent() //parical removal after finished animation
                })
                
                nodeA?.removeFromParent()
                nodeB?.removeFromParent()
                score+=10 //basic score increment for now
                
            }
            
        }
        
        
        
        
        
        
        
        
        
        
        
        
        //also game over if invader hits a space defender
        if(nodeA?.name=="invader" && nodeB?.name=="SpaceDefender" || nodeB?.name=="invader" && nodeA?.name=="SpaceDefender" && gameLevel != -1){
            //game over
            gameLevel = -1
            
        }
        
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameLevel==0){
            gameLevel+=1
            let touchNode = self.childNode(withName: "FirstTouch") as? SKLabelNode
            touchNode?.removeFromParent()
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
                spaceDefender.physicsBody?.velocity.dx = (CGFloat(500*data.acceleration.x))
            }
            else if (data.acceleration.x < -0.2 && spaceDefender.position.x-spaceDefender.size.width/2 > 0 ) {
                spaceDefender.physicsBody?.velocity.dx = (CGFloat(500*data.acceleration.x))
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
