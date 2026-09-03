//
//  SISpace.m
//  Silica
//

#import "SISpace.h"

@implementation SISpace

- (instancetype)initWithSpaceID:(CGSSpaceID)spaceID type:(CGSSpaceType)type uuid:(NSString *)uuid isFullscreen:(BOOL)isFullscreen {
    self = [super init];
    if (self) {
        _spaceID = spaceID;
        _type = type;
        _uuid = [uuid copy];
        _isFullscreen = isFullscreen;
    }
    return self;
}

+ (instancetype)spaceWithDescription:(NSDictionary *)description {
    NSNumber *spaceID = description[@"ManagedSpaceID"];
    if (![spaceID isKindOfClass:[NSNumber class]]) return nil;

    NSNumber *type = description[@"type"];
    NSString *uuid = description[@"uuid"];

    return [[self alloc] initWithSpaceID:spaceID.unsignedLongValue
                                    type:(CGSSpaceType)([type isKindOfClass:[NSNumber class]] ? type.unsignedIntValue : 0)
                                    uuid:[uuid isKindOfClass:[NSString class]] ? uuid : @""
                            isFullscreen:description[@"TileLayoutManager"] != nil];
}

+ (NSArray<SISpace *> *)spacesWithScreenDescription:(NSDictionary *)screenDescription {
    NSMutableArray<SISpace *> *spaces = [NSMutableArray array];
    NSArray *descriptions = screenDescription[@"Spaces"];
    if (![descriptions isKindOfClass:[NSArray class]]) return spaces;

    for (NSDictionary *description in descriptions) {
        if (![description isKindOfClass:[NSDictionary class]]) continue;
        SISpace *space = [self spaceWithDescription:description];
        if (space) [spaces addObject:space];
    }
    return spaces;
}

+ (SISpace *)currentSpaceWithScreenDescription:(NSDictionary *)screenDescription {
    NSDictionary *description = screenDescription[@"Current Space"];
    if (![description isKindOfClass:[NSDictionary class]]) return nil;
    return [self spaceWithDescription:description];
}

- (BOOL)isEqual:(id)object {
    if (self == object) return YES;
    if (![object isKindOfClass:[SISpace class]]) return NO;
    return self.spaceID == ((SISpace *)object).spaceID;
}

- (NSUInteger)hash {
    return (NSUInteger)self.spaceID;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<SISpace id=%lu type=%u uuid=%@%@>", (unsigned long)self.spaceID, (unsigned)self.type, self.uuid, self.isFullscreen ? @" fullscreen" : @""];
}

@end
