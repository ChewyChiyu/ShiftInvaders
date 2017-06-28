//
//  Bullet.swift
//  SpaceInvader
//
//  Created by Evan Chen on 6/26/17.
//  Copyright © 2017 Evan Chen. All rights reserved.
//

import Foundation
import SpriteKit

class Bullet : SKSpriteNode{
    
    init(){
       
        super.init(texture: SKTexture(imageNamed: "Projectile"), color : UIColor.clear, size : SKTexture(imageNamed: "Projectile").size() )
        self.name = "bullet"
        self.setScale(0.5)
        self.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.size.width, height: self.size.height))
        self.physicsBody?.affectedByGravity = false
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.contactTestBitMask = UInt32.max
        self.physicsBody?.collisionBitMask = 0 // pass through
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
