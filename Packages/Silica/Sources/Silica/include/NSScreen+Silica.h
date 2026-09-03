//
//  NSScreen+Silica.h
//  Silica
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>
#import "SISpace.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A category defining helper methods on NSScreen that are generally useful for window management.
 */
@interface NSScreen (Silica)

#pragma mark Frames

/// Frame in top-left-origin (CoreGraphics / accessibility) coordinates, including menu bar and dock.
- (CGRect)frameIncludingDockAndMenu;
/// Visible frame in top-left-origin coordinates, excluding menu bar and dock.
- (CGRect)frameWithoutDockOrMenu;

#pragma mark Spaces

/// Every space on every display, in the order the window server reports displays. Empty when the window server cannot be queried.
+ (NSArray<SISpace *> *)allSpaces;
/// The window server's managed display identifier for this screen, or nil.
- (nullable NSString *)managedDisplayID;
/// Spaces on this screen. When displays do not have separate spaces, every screen reports the shared set.
- (NSArray<SISpace *> *)spaces;
/// The space currently shown on this screen, or nil.
- (nullable SISpace *)currentSpace;

@end

NS_ASSUME_NONNULL_END
