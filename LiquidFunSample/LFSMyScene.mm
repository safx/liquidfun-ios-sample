//
//  LFSMyScene.m
//  LiquidFunSample
//
//  Created by Safx Developer on 2014/01/19.
//  Copyright (c) 2014年 Safx Developers. All rights reserved.
//

#include <deque>
#include <Box2D/Box2d.h>
#import "LFSMyScene.h"

const float DISPLAY_SCALE = 32.0;

@interface LFSMyScene () {
    b2World* _world;
    std::deque<b2Body*> _bodies;
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
        
        // Creating a ground box
        CGSize s = UIScreen.mainScreen.bounds.size;
        
        b2BodyDef groundBodyDef;
        groundBodyDef.position.Set(s.width / DISPLAY_SCALE / 2, -10.0f);
        
        b2Body* groundBody = _world->CreateBody(&groundBodyDef);
        
        b2PolygonShape groundBox;
        groundBox.SetAsBox(s.width / DISPLAY_SCALE / 2, 10.0f);
        
        groundBody->CreateFixture(&groundBox, 0.0f);
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
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position.Set(location.x / DISPLAY_SCALE, location.y / DISPLAY_SCALE);
        b2Body* body = _world->CreateBody(&bodyDef);
        
        b2PolygonShape dynamicBox;
        dynamicBox.SetAsBox(size.width / DISPLAY_SCALE / 2, size.height / DISPLAY_SCALE / 2);
        
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &dynamicBox;
        fixtureDef.density = 1.0f;
        fixtureDef.friction = 0.3f;
        fixtureDef.restitution = 0.8f;
        body->CreateFixture(&fixtureDef);
        
        body->SetUserData((__bridge void*) node);
        _bodies.push_back(body);
    }
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    using namespace std;
    
    const float32 timeStep = 1.0f / 60.0f;
    const int32 velocityIterations = 6;
    const int32 positionIterations = 2;
    
    _world->Step(timeStep, velocityIterations, positionIterations);
    for_each(begin(_bodies), end(_bodies), [](b2Body* body) {
        const b2Vec2 position = body->GetPosition();
        const float32 angle = body->GetAngle();
        
        SKSpriteNode* sprite = (__bridge SKSpriteNode*) body->GetUserData();
        sprite.position = CGPointMake(position.x * DISPLAY_SCALE, position.y * DISPLAY_SCALE);
        sprite.zRotation = angle;
    });
}

@end
