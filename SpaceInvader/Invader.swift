//
//  Invader.swift
//  SpaceInvader
//
//  Created by Evan Chen on 6/27/17.
//  Copyright © 2017 Evan Chen. All rights reserved.
//

import Foundation
import SpriteKit

class Invader : SKSpriteNode{
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //will be giving AI move commands to invaders here so they move around instead of a linear path
    }
}
