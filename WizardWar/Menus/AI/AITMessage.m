//
//  AITMessageStart.m
//  WizardWar
//
//  Created by Sean Hess on 8/26/13.
//  Copyright (c) 2013 Orbital Labs. All rights reserved.
//

#import "AITMessage.h"
#import "NSArray+Functional.h"

#define DURATION 2.0
#define CHANCE_ON_CAST 0.25


@interface AITMessage ()
@property (nonatomic, strong) NSMutableDictionary * usedMessages;
@property (nonatomic) NSInteger lastWizardHealth;
@property (nonatomic) NSInteger lastOpponentHealth;
@end




@implementation AITMessage

-(id)init {
    if ((self = [super init])) {
        self.usedMessages = [NSMutableDictionary dictionary];
        self.lastWizardHealth = MAX_HEALTH;
        self.lastOpponentHealth = MAX_HEALTH;
    }
    return self;
}

-(BOOL)randomShouldSpeak {
    return ((arc4random() % 100) < self.chance*100);
}

-(AIAction *)preAction {
    return [AIAction message:[self.start randomItem]];
}

-(BOOL)messageIsOld:(AIGameState*)game {
    return (game.wizard.message && game.currentTick > (DURATION/game.interval + game.messageTick));
}

-(AIAction *)useUpMessageFrom:(NSMutableArray*)array {
    // uses the message up
    NSString * message = [[array filter:^BOOL(NSString * message) {
        return (self.usedMessages[message] == nil);
    }] randomItem];
    if (!message) return nil;
    self.usedMessages[message] = @(YES);
    return [AIAction message:message];
}

-(AIAction *)suggestedAction:(AIGameState *)game {
    
    AIAction * action = nil;
    
    if ([self messageIsOld:game]) {
        if ([self.cast containsObject:game.wizard.message] || [self.castOther containsObject:game.wizard.message] || [self.start containsObject:game.wizard.message] || [self.hits containsObject:game.wizard.message] || [self.wounds containsObject:game.wizard.message]) {
            return [AIAction clearMessage];
        }
    }
    
    if (![self randomShouldSpeak]) return nil;
    
    Spell * justCastSpell = game.justCastSpell;
    Spell * justCastSpellOther = game.justCastSpellOther;
    
    if (justCastSpell && self.cast) {
        action = [self useUpMessageFrom:self.cast];
    }
    
    else if (justCastSpellOther && self.castOther) {
        action = [self useUpMessageFrom:self.castOther];
    }
    
    else if (self.wounds && game.wizard.health < self.lastWizardHealth) {
        self.lastWizardHealth = game.wizard.health;
        action = [self useUpMessageFrom:self.wounds];
    }
    
    // sleep isn't a hit!
    else if (self.hits && game.opponent.health < self.lastOpponentHealth) {
        self.lastOpponentHealth = game.opponent.health;
        action = [self useUpMessageFrom:self.hits];        
    }
    
    return action;
}

-(AIAction*)endAction:(BOOL)didWin {
    if (didWin && self.win) {
        return [AIAction message:[self.win randomItem]];
    }
    
    else if (!didWin && self.lose) {
        return [AIAction message:[self.lose randomItem]];
    }
    
    return nil;
}


+(id)withStart:(NSArray*)messages {
    AITMessage * tactic = [AITMessage new];
    tactic.start = messages;
    return tactic;
}
+(id)withCast:(NSArray*)messages chance:(float)chance {
    AITMessage * tactic = [AITMessage new];
    tactic.cast = [NSMutableArray arrayWithArray:messages];
    tactic.chance = chance;
    return tactic;
}
+(id)withCastOther:(NSArray *)messages chance:(float)chance {
    AITMessage * tactic = [AITMessage new];
    tactic.castOther = [NSMutableArray arrayWithArray:messages];
    tactic.chance = chance;
    return tactic;
}
+(id)withHits:(NSArray*)messages chance:(float)chance {
    AITMessage * tactic = [AITMessage new];
    tactic.hits = [NSMutableArray arrayWithArray:messages];
    tactic.chance = chance;
    return tactic;
}
+(id)withWounds:(NSArray*)messages chance:(float)chance {
    AITMessage * tactic = [AITMessage new];
    tactic.wounds = [NSMutableArray arrayWithArray:messages];
    tactic.chance = chance;
    return tactic;
}
+(id)withWin:(NSArray*)messages {
    AITMessage * tactic = [AITMessage new];
    tactic.win = messages;
    return tactic;
}
+(id)withLose:(NSArray*)messages {
    AITMessage * tactic = [AITMessage new];
    tactic.lose = messages;
    return tactic;
}
@end
