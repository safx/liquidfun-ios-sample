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
    std::vector<SKNode*> _water;
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
    const static CGSize boxsize = CGSizeMake(32, 32);
    static b2PolygonShape boxShape;
    boxShape.SetAsBox(boxsize.width / DISPLAY_SCALE / 2, boxsize.height / DISPLAY_SCALE / 2);
    auto createFixtureWithValues = [](b2Body* body, b2Shape* shape, float density, float friction, float restitution) {
        b2FixtureDef def;
        def.shape = shape;
        def.density = density;
        def.friction = friction;
        def.restitution = restitution;
        body->CreateFixture(&def);
    };
    
    auto createBody = [self](CGPoint& pos) -> b2Body* {
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position.Set(pos.x / DISPLAY_SCALE, pos.y / DISPLAY_SCALE);
        return _world->CreateBody(&bodyDef);
    };
    
    auto addBox = [self,createBody,createFixtureWithValues](CGPoint& pos) {
        SKSpriteNode* node = [SKSpriteNode spriteNodeWithColor:UIColor.whiteColor size:boxsize];
        node.position = pos;
        [self addChild:node];
        
        b2Body* body = createBody(pos);
        createFixtureWithValues(body, &boxShape, 1.0f, 0.3f, 0.8f);
        body->SetUserData((__bridge void*) node);
    };
    
    static UIBezierPath* ovalPath = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(-16, -16, 32, 32)];
    static b2CircleShape ballShape;
    ballShape.m_radius = 32 / DISPLAY_SCALE / 2;
    auto addBall = [self,createBody,createFixtureWithValues](CGPoint& pos) {
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
    auto addWater = [self](CGPoint& pos) {
        b2ParticleGroupDef groupDef;
        groupDef.shape = &ballShape;
        groupDef.flags = b2_tensileParticle;
        groupDef.position.Set(pos.x / DISPLAY_SCALE, pos.y / DISPLAY_SCALE);
        b2ParticleGroup* group = _world->CreateParticleGroup(groupDef);
        
        for (size_t i = 0; i < group->GetParticleCount(); ++i) {
            SKShapeNode* node = SKShapeNode.alloc.init;
            node.path = ovalPath2.CGPath;
            node.fillColor = UIColor.blueColor;
            node.lineWidth = 0;
            node.position = pos;
            [self addChild:node];
            
            _water.push_back(node);
        }
    };
    
    static int count = 0;

    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        switch (count % 3) {
            case 0: addBox(location); break;
            case 1: addBall(location); break;
            case 2: addWater(location); break;
        }
    }
    ++count;
}

-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
    const float32 timeStep = 1.0f / 60.0f;
    const int32 velocityIterations = 6;
    const int32 positionIterations = 2;
    
    _world->Step(timeStep, velocityIterations, positionIterations);
    
    for (b2Body* body = _world->GetBodyList(); body != nullptr;) {
        b2Body* next = body->GetNext();
        
        const b2Vec2 position = body->GetPosition();
        const float32 angle = body->GetAngle();
        
        SKNode* node = (__bridge SKNode*) body->GetUserData();
        if (position.y >= 0) {
            node.position = CGPointMake(position.x * DISPLAY_SCALE, position.y * DISPLAY_SCALE);
            node.zRotation = angle;
        } else if (node) {
            [node removeFromParent];
            _world->DestroyBody(body);
        }
        body = next;
    }

    using namespace std;
    
    b2Vec2* v = _world->GetParticlePositionBuffer();
    int i = 0;
    auto it = remove_if(begin(_water), end(_water), [self, &v, &i](SKNode* node){
        const bool is_remove = v->y < 0;
        if (is_remove) {
            _world->DestroyParticle(i);
            [node removeFromParent];
        } else {
            node.position = CGPointMake(v->x * DISPLAY_SCALE, v->y * DISPLAY_SCALE);
        }
        ++i;
        ++v;
        return is_remove;
    });
    _water.erase(it, end(_water));
}

@end
