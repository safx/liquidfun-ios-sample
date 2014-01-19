//
//  LFSMyScene.m
//  LiquidFunSample
//
//  Created by Safx Developer on 2014/01/19.
//  Copyright (c) 2014年 Safx Developers. All rights reserved.
//

#include <Box2D/Box2d.h>
#import "LFSMyScene.h"

@interface LFSMyScene () {
    b2World* _world;
}
@end

@implementation LFSMyScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */
        
        self.backgroundColor = [SKColor colorWithRed:0.15 green:0.15 blue:0.3 alpha:1.0];
        
        // Creating a World
        b2Vec2 gravity(0.0f, -10.0f);
        _world = new b2World(gravity);
    }
    return self;
}

-(void)dealloc {
    delete _world;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    /* Called when a touch begins */
    
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        CGSize size = CGSizeMake(32, 32);
        
        SKSpriteNode *node = [SKSpriteNode spriteNodeWithColor:UIColor.whiteColor size:size];
        node.position = location;
        
        [self addChild:node];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}

@end
