//
//  LFSMyScene.m
//  LiquidFunSample
//
//  Created by Safx Developer on 2014/01/19.
//  Copyright (c) 2014年 Safx Developers. All rights reserved.
//

#include <vector>
#include <Box2D/Box2d.h>
#import "LFSMyScene.h"

const float DISPLAY_SCALE = 32.0;

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
        
        _world->SetParticleRadius(1.0 / 8);

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

    auto createFixtureWithValues = [](b2Body* body, const b2Shape* shape, float density, float friction, float restitution) {
        b2FixtureDef def;
        def.shape = shape;
        def.density = density;
        def.friction = friction;
        def.restitution = restitution;
        body->CreateFixture(&def);
    };
    
    auto createBody = [self](const CGPoint& pos) -> b2Body* {
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position.Set(pos.x / DISPLAY_SCALE, pos.y / DISPLAY_SCALE);
        return _world->CreateBody(&bodyDef);
    };
    
    auto addBox = [self,createBody,createFixtureWithValues](const CGPoint& pos, const CGSize& size) {
        b2PolygonShape boxShape;
        boxShape.SetAsBox(size.width / 2, size.height / 2);

        SKSpriteNode* node = [SKSpriteNode spriteNodeWithColor:UIColor.whiteColor size:CGSizeMake(size.width * DISPLAY_SCALE, size.height * DISPLAY_SCALE)];
        node.position = pos;
        [self addChild:node];
        
        b2Body* body = createBody(pos);
        createFixtureWithValues(body, &boxShape, 1.0f, 0.3f, 0.1f);
        body->SetUserData((__bridge void*) node);
    };
    
    auto addBall = [self,createBody,createFixtureWithValues](const CGPoint& pos, float radius) {
        const float r = radius * DISPLAY_SCALE;
        UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(-r, -r, r*2, r*2)];
        b2CircleShape ballShape;
        ballShape.m_radius = radius;

        SKShapeNode* node = SKShapeNode.alloc.init;
        node.path = ovalPath.CGPath;
        node.fillColor = UIColor.whiteColor;
        node.lineWidth = 0;
        node.position = pos;
        [self addChild:node];
        
        b2Body* body = createBody(pos);
        createFixtureWithValues(body, &ballShape, 1.0f, 0.3f, 0.4f);
        body->SetUserData((__bridge void*) node);
    };
    
    static UIBezierPath* ovalPath2 = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(-4, -4, 8, 8)];
    auto addWater = [self](const CGPoint& pos) {
        b2CircleShape ballShape;
        ballShape.m_radius = 32 / DISPLAY_SCALE / 2;

        b2ParticleGroupDef groupDef;
        groupDef.shape = &ballShape;
        groupDef.flags = b2_tensileParticle;
        groupDef.position.Set(pos.x / DISPLAY_SCALE, pos.y / DISPLAY_SCALE);
        b2ParticleGroup* group = _world->CreateParticleGroup(groupDef);
        
        int32 offset = group->GetBufferIndex();
        void** userdata = _world->GetParticleUserDataBuffer() + offset;
        for (size_t i = 0; i < group->GetParticleCount(); ++i) {
            SKShapeNode* node = SKShapeNode.alloc.init;
            node.path = ovalPath2.CGPath;
            node.fillColor = UIColor.blueColor;
            node.lineWidth = 0;
            node.position = pos;
            [self addChild:node];
            
            *userdata = (__bridge void*) node;
            ++userdata;
        }
    };
    
    static int count = 0;

    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        switch (count % 3) {
            case 0: addBox(location, CGSizeMake(1,1)); break;
            case 1: addBall(location, 0.5); break;
            case 2: addWater(location); break;
        }
    }
    ++count;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    static CFTimeInterval previousTime = 0;
    double duration = currentTime - previousTime;
    previousTime = currentTime;
    
    const float32 timeStep = duration;
    const int32 velocityIterations = 6;
    const int32 positionIterations = 2;
    
    _world->Step(timeStep, velocityIterations, positionIterations);
    
    for (b2Body* body = _world->GetBodyList(); body != nullptr; body = body->GetNext()) {
        const b2Vec2 position = body->GetPosition();
        const float32 angle = body->GetAngle();
        
        SKNode* node = (__bridge SKNode*) body->GetUserData();
        node.position = CGPointMake(position.x * DISPLAY_SCALE, position.y * DISPLAY_SCALE);
        node.zRotation = angle;
    }
    
    b2Vec2* v = _world->GetParticlePositionBuffer();
    void** userdata = _world->GetParticleUserDataBuffer();
    uint32* flags = _world->GetParticleFlagsBuffer();
    for (int i = 0; i < _world->GetParticleCount(); ++i, ++v, ++flags, ++userdata) {
        const bool is_remove = v->y < 0;
        SKNode* node = (__bridge SKNode*) *userdata;
        if (is_remove) {
            *flags |= b2_zombieParticle;
            [node removeFromParent];
        } else {
            node.position = CGPointMake(v->x * DISPLAY_SCALE, v->y * DISPLAY_SCALE);
        }
    }
}

@end
