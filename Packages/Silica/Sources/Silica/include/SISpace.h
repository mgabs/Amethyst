//
//  SISpace.h
//  Silica
//

#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>
#import "CGSInternal/CGSSpace.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A Mission Control space as reported by CGSCopyManagedDisplaySpaces.
 Equality and hashing use spaceID only.
 */
@interface SISpace : NSObject

@property (nonatomic, readonly) CGSSpaceID spaceID;
@property (nonatomic, readonly) CGSSpaceType type;
@property (nonatomic, readonly, copy) NSString *uuid;
/// YES when the space is a fullscreen-app space (has a TileLayoutManager entry).
@property (nonatomic, readonly) BOOL isFullscreen;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithSpaceID:(CGSSpaceID)spaceID type:(CGSSpaceType)type uuid:(NSString *)uuid isFullscreen:(BOOL)isFullscreen NS_DESIGNATED_INITIALIZER;

/// Parses one entry of a screen description's "Spaces" array or its "Current Space". Returns nil without a numeric ManagedSpaceID.
+ (nullable instancetype)spaceWithDescription:(NSDictionary *)description;
/// Parses the "Spaces" array of one CGSCopyManagedDisplaySpaces entry, in order, skipping malformed entries.
+ (NSArray<SISpace *> *)spacesWithScreenDescription:(NSDictionary *)screenDescription;
/// Parses the "Current Space" of one CGSCopyManagedDisplaySpaces entry.
+ (nullable SISpace *)currentSpaceWithScreenDescription:(NSDictionary *)screenDescription;

@end

NS_ASSUME_NONNULL_END
