//
//  NSScreen+Silica.m
//  Silica
//

#import "NSScreen+Silica.h"

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

@end
