//
//  ViewController.m
//  blong
//
//  Created by Peter Ketcham on 8/7/15.
//  Copyright (c) 2015 Peter Ketcham. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () <UICollisionBehaviorDelegate>
@property (nonatomic, strong) UIView *playingField;
@property (nonatomic, strong) UIView *topPaddle;
@property (nonatomic, strong) UIView *bottomPaddle;
@property (nonatomic, strong) UIView *puck;
@property (nonatomic, strong) UILabel *scoreboard;
@property (nonatomic, assign) NSInteger topPaddleScore;
@property (nonatomic, assign) NSInteger bottomPaddleScore;
@property (nonatomic, strong) UIView *lastPaddleToStrikePuck;
@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;
@property (nonatomic, strong) UIDynamicItemBehavior *dynamicItemBehavior;
@property (nonatomic, strong) UICollisionBehavior *puckCollisionBehavior;
@property (nonatomic, strong) GKRandomDistribution *topPaddleRandomDistribution;
@property (nonatomic, strong) GKRandomDistribution *puckHorizontalRandomDistribution;
@property (nonatomic, strong) GKRandomDistribution *puckVerticalRandomDistribution;
@property (nonatomic, strong) UIPushBehavior *puckPushBehavior;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.autoresizesSubviews = NO;
    self.playingField = self.view;
    self.playingField.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    
    CGRect topPaddleRectangle = CGRectMake(self.playingField.bounds.size.width/2.0, 40.0, 100.0, 10.0);
    self.topPaddle = [[UIView alloc] initWithFrame:topPaddleRectangle];
    self.topPaddle.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    [self.playingField addSubview:self.topPaddle];
    
    CGRect bottomPaddleRectangle = CGRectMake(self.playingField.bounds.size.width/2.0, self.playingField.bounds.size.height - 50.0, 100.0, 10.0);
    self.bottomPaddle = [[UIView alloc] initWithFrame:bottomPaddleRectangle];
    self.bottomPaddle.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0];
    [self.playingField addSubview:self.bottomPaddle];
    
    CGRect puckRectangle = CGRectMake(self.playingField.bounds.size.width/2.0, self.playingField.bounds.size.height/2.0, 20.0, 20.0);
    self.puck = [[UIView alloc] initWithFrame:puckRectangle];
    self.puck.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    [self.playingField addSubview:self.puck];
    
    CGRect scoreboardRectangle = CGRectMake(self.playingField.bounds.size.width/2.0 - 100.0, 100.0, 200.0, 25.0);
    self.scoreboard = [[UILabel alloc] initWithFrame:scoreboardRectangle];
    self.scoreboard.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.topPaddleScore = 0;
    self.bottomPaddleScore = 0;
    self.scoreboard.text = [NSString stringWithFormat:@"Top: %ld      Bottom: %ld", (long)self.topPaddleScore, (long)self.bottomPaddleScore];
    self.scoreboard.textAlignment = NSTextAlignmentCenter;
    [self.playingField addSubview:self.scoreboard];
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBottomPaddle:)];
    [self.bottomPaddle addGestureRecognizer:panGestureRecognizer];
    
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.playingField];
    
    self.dynamicItemBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.puck]];
    self.dynamicItemBehavior.elasticity = 1.0;
    self.dynamicItemBehavior.friction = 0.0;
    self.dynamicItemBehavior.resistance = 0.0;
    self.dynamicItemBehavior.allowsRotation = NO;
    [self.dynamicItemBehavior addLinearVelocity:CGPointMake(100.0, 150.0) forItem:self.puck];
    [self.dynamicAnimator addBehavior:self.dynamicItemBehavior];
    
    self.puckCollisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.puck]];
    self.puckCollisionBehavior.collisionDelegate = self;
    [self.puckCollisionBehavior addBoundaryWithIdentifier:@"westWall" fromPoint:CGPointMake(0.0, 0.0) toPoint:CGPointMake(0.0, self.playingField.bounds.size.height)];
    [self.puckCollisionBehavior addBoundaryWithIdentifier:@"eastWall" fromPoint:CGPointMake(self.playingField.bounds.size.width, 0.0) toPoint:CGPointMake(self.playingField.bounds.size.width, self.playingField.bounds.size.height)];
    [self.puckCollisionBehavior addBoundaryWithIdentifier:@"northWall" fromPoint:CGPointMake(0.0, 0.0) toPoint:CGPointMake(self.playingField.bounds.size.width, 0.0)];
    [self.puckCollisionBehavior addBoundaryWithIdentifier:@"southWall" fromPoint:CGPointMake(0.0, self.playingField.bounds.size.height) toPoint:CGPointMake(self.playingField.bounds.size.width, self.playingField.bounds.size.height)];
    [self.puckCollisionBehavior addBoundaryWithIdentifier:@"topPaddle" forPath:[UIBezierPath bezierPathWithRect:self.topPaddle.frame]];
    [self.puckCollisionBehavior addBoundaryWithIdentifier:@"bottomPaddle" forPath:[UIBezierPath bezierPathWithRect:self.bottomPaddle.frame]];
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(moveTopPaddle:) userInfo:nil repeats:NO];
    self.topPaddleRandomDistribution = [GKRandomDistribution distributionWithLowestValue:1 highestValue:5];
    self.puckHorizontalRandomDistribution = [GKRandomDistribution distributionWithLowestValue:-25 highestValue:25];
    self.puckVerticalRandomDistribution = [GKRandomDistribution distributionWithLowestValue:150 highestValue:250];
    [self.dynamicAnimator addBehavior:self.puckCollisionBehavior];
    self.lastPaddleToStrikePuck = nil;
}

- (void)moveTopPaddle:(NSTimer *)timer {
    self.topPaddle.center = CGPointMake(self.puck.center.x, self.topPaddle.center.y);
    [self.puckCollisionBehavior removeBoundaryWithIdentifier:@"topPaddle"];
    [self.puckCollisionBehavior addBoundaryWithIdentifier:@"topPaddle" forPath:[UIBezierPath bezierPathWithRect:self.topPaddle.frame]];
    NSInteger topPaddleTimeInterval = [self.topPaddleRandomDistribution nextInt];
    [NSTimer scheduledTimerWithTimeInterval:topPaddleTimeInterval target:self selector:@selector(moveTopPaddle:) userInfo:nil repeats:NO];
}

- (void)moveBottomPaddle:(UIPanGestureRecognizer *)panGestureRecognizer {
    CGPoint newBottomPaddleCenter = [panGestureRecognizer locationInView:self.playingField];
    self.bottomPaddle.center = CGPointMake(newBottomPaddleCenter.x, self.bottomPaddle.center.y);
    [self.puckCollisionBehavior removeBoundaryWithIdentifier:@"bottomPaddle"];
    [self.puckCollisionBehavior addBoundaryWithIdentifier:@"bottomPaddle" forPath:[UIBezierPath bezierPathWithRect:self.bottomPaddle.frame]];
 }

- (void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(NSString *)identifier atPoint:(CGPoint)p {
    BOOL puckStruckWallBoundary;
    BOOL topPaddleCatapultMode = NO;
    BOOL bottomPaddleCatapultMode = NO;
    NSInteger puckHorizontalVelocity;
    NSInteger puckVerticalVelocity;
    
    if ([identifier isEqualToString:@"northWall"] || [identifier isEqualToString:@"southWall"] || [identifier isEqualToString:@"westWall"] || [identifier isEqualToString:@"eastWall"]) {
        puckStruckWallBoundary = YES;
    } else {
        puckStruckWallBoundary = NO;
    }
    
    if (puckStruckWallBoundary == YES) {
        if ([identifier isEqualToString:@"northWall"]) {
            // bottom paddle scores a point
            self.bottomPaddleScore = self.bottomPaddleScore + 1;
        } else if ([identifier isEqualToString:@"southWall"]) {
            // top paddle scores a point
            self.topPaddleScore = self.topPaddleScore + 1;
        } else {
            // puck hit west wall or east wall and thus went out of bounds
            // last paddle to strike puck loses, unless neither paddle struck the puck (because the puck went out of bounds immediately) in which case there is no change of score
            if (self.lastPaddleToStrikePuck == self.topPaddle) {
                self.bottomPaddleScore = self.bottomPaddleScore + 1;
            }
            if (self.lastPaddleToStrikePuck == self.bottomPaddle) {
                self.topPaddleScore = self.topPaddleScore + 1;
            }
        }
        // update score
        self.scoreboard.text = [NSString stringWithFormat:@"Top: %ld      Bottom: %ld", (long)self.topPaddleScore, (long)self.bottomPaddleScore];
        // check for catapult mode
        if (self.topPaddleScore % 5 == 0 && self.topPaddleScore > 0) {
            topPaddleCatapultMode = YES;
        }
        if (self.bottomPaddleScore % 5 == 0 && self.bottomPaddleScore > 0) {
            bottomPaddleCatapultMode = YES;
        }
        // remove old puck
        [self.puckCollisionBehavior removeItem:self.puck];
        [self.dynamicItemBehavior removeItem:self.puck];
        [self.puck removeFromSuperview];
        // allocate new puck
        CGRect puckRectangle = CGRectMake(self.playingField.bounds.size.width/2.0, self.playingField.bounds.size.height/2.0, 20.0, 20.0);
        self.puck = [[UIView alloc] initWithFrame:puckRectangle];
        self.puck.backgroundColor = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
        [self.playingField addSubview:self.puck];
        [self.dynamicItemBehavior addItem:self.puck];
        
        if (topPaddleCatapultMode == YES || bottomPaddleCatapultMode == YES) {
            // launch puck via catapult
            self.puckPushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.puck] mode:UIPushBehaviorModeContinuous];
            if (topPaddleCatapultMode == YES) {
                self.puckPushBehavior.pushDirection = CGVectorMake(0.1, 0.2);
            } else {
                self.puckPushBehavior.pushDirection = CGVectorMake(0.1, -0.2);
            }
            [self.dynamicAnimator addBehavior:self.puckPushBehavior];
            self.puckPushBehavior.active = YES;
        } else {
            puckHorizontalVelocity = [self.puckHorizontalRandomDistribution nextInt];
            puckVerticalVelocity = [self.puckVerticalRandomDistribution nextInt];
            if (puckVerticalVelocity % 2 == 1) {
            puckVerticalVelocity = (-1)*puckVerticalVelocity;
            }
            [self.dynamicItemBehavior addLinearVelocity:CGPointMake(puckHorizontalVelocity, puckVerticalVelocity) forItem:self.puck];
            NSLog(@"%ld %ld", puckHorizontalVelocity, puckVerticalVelocity);
        }
        
        [self.puckCollisionBehavior addItem:self.puck];
    } else {
        // puck hit a paddle
        self.puckPushBehavior.active = NO;
        if ([identifier isEqualToString:@"topPaddle"]) {
            self.lastPaddleToStrikePuck = self.topPaddle;
        } else {
            self.lastPaddleToStrikePuck = self.bottomPaddle;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
