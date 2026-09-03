//
//  NSScreen+Silica.m
//  Silica
//

#import "NSScreen+Silica.h"
#import "CGSInternal/CGSConnection.h"
#import "CGSInternal/CGSDisplays.h"
#import "CGSInternal/CGSSpace.h"

@implementation NSScreen (Silica)

+ (NSScreen *)originScreen {
    for (NSScreen *screen in self.screens) {
        if (CGPointEqualToPoint(screen.frame.origin, CGPointZero)) {
            return screen;
        }
    }
    return nil;
}

- (CGRect)frameIncludingDockAndMenu {
    NSScreen *primaryScreen = [NSScreen originScreen];
    CGRect f = self.frame;
    f.origin.y = NSHeight([primaryScreen frame]) - NSHeight(f) - f.origin.y;
    return f;
}

- (CGRect)frameWithoutDockOrMenu {
    NSScreen *primaryScreen = [NSScreen originScreen];
    CGRect f = [self visibleFrame];
    f.origin.y = NSHeight([primaryScreen frame]) - NSHeight(f) - f.origin.y;
    return f;
}

#pragma mark Spaces

+ (NSArray<NSDictionary *> *)managedDisplayDescriptions {
    CFArrayRef descriptions = CGSCopyManagedDisplaySpaces(CGSMainConnectionID());
    if (!descriptions) return @[];
    return CFBridgingRelease(descriptions);
}

+ (NSArray<SISpace *> *)allSpaces {
    NSMutableArray<SISpace *> *spaces = [NSMutableArray array];
    for (NSDictionary *description in [self managedDisplayDescriptions]) {
        [spaces addObjectsFromArray:[SISpace spacesWithScreenDescription:description]];
    }
    return spaces;
}

- (NSString *)managedDisplayID {
    CFStringRef displayID = CGSCopyBestManagedDisplayForRect(CGSMainConnectionID(), self.frameIncludingDockAndMenu);
    if (!displayID) return nil;
    return CFBridgingRelease(displayID);
}

- (NSDictionary *)managedDisplayDescription {
    NSArray<NSDictionary *> *descriptions = [NSScreen managedDisplayDescriptions];
    if (descriptions.count == 0) return nil;
    if (![NSScreen screensHaveSeparateSpaces]) return descriptions.firstObject;

    NSString *displayID = self.managedDisplayID;
    if (!displayID) return nil;
    for (NSDictionary *description in descriptions) {
        if ([description[@"Display Identifier"] isEqual:displayID]) return description;
    }
    return nil;
}

- (NSArray<SISpace *> *)spaces {
    NSDictionary *description = self.managedDisplayDescription;
    return description ? [SISpace spacesWithScreenDescription:description] : @[];
}

- (SISpace *)currentSpace {
    NSDictionary *description = self.managedDisplayDescription;
    return description ? [SISpace currentSpaceWithScreenDescription:description] : nil;
}

@end
