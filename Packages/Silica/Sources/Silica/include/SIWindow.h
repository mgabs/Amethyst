//
//  SIWindow.h
//  Silica
//

#import <AppKit/AppKit.h>
#import "CGSInternal/CGSSpace.h"
#import "SIAccessibilityElement.h"

NS_ASSUME_NONNULL_BEGIN

@class SIApplication;

/**
 *  Encapsulates a window element.
 */
@interface SIWindow : SIAccessibilityElement

#pragma mark Window Accessors

/**
 * Returns the currently focused window.
 *
 *  @return A SIWindow object representing the currently focused window or nil if no window is focused.
 */
+ (nullable SIWindow *)focusedWindow;

#pragma mark Window Properties

/**
 * Returns the window ID of the window.
 *
 * @return The window ID of the window.
 */
- (CGWindowID)windowID;

/**
 *  Returns the title of the window.
 *
 *  @return The title of the window or nil if the window has no title.
 */
- (nullable NSString *)title;

/**
 *  Returns a BOOL indicating whether or not the window is minimized.
 *
 *  @return YES if the window is minimized and NO otherwise.
 */
- (BOOL)isWindowMinimized;

/**
 *  Returns a BOOL indicating whether or not the window is normal, i.e., if its role is a standard window.
 *
 *  @return YES if the window is normal and NO otherwise.
 */
- (BOOL)isNormalWindow;

/**
 *  Returns a BOOL indicating whether or not the window is a sheet.
 *
 *  @return YES if the window is a sheet and NO otherwise.
 */
- (BOOL)isSheet;

/**
 *  Returns a BOOL indicating whether or not the window is active and on screen.
 *
 *  @return YES if the window is active and on screen and NO otherwise.
 */
- (BOOL)isActive;

/**
 *  Returns a BOOL indicating whether or not the window is on screen.
 *
 *  @return YES if the window is on screen and NO otherwise.
 */
- (BOOL)isOnScreen;

#pragma mark Window Server Queries

/// The window server ID of the space this window is on, or 0 when unknown.
- (CGSSpaceID)managedSpaceID;

/// IDs of every window currently on screen, across all displays' active spaces. Desktop-layer windows are not filtered out. One window-list copy.
+ (NSSet<NSNumber *> *)onScreenWindowIDs;

/// IDs of on-screen windows whose bounds contain `point`, front to back. One window-list copy.
+ (NSArray<NSNumber *> *)onScreenWindowIDsAtPoint:(CGPoint)point NS_SWIFT_NAME(onScreenWindowIDs(at:));

/// Pure helper behind onScreenWindowIDsAtPoint:. `descriptions` is a CGWindowListCopyWindowInfo result.
+ (NSArray<NSNumber *> *)windowIDsAtPoint:(CGPoint)point inDescriptions:(NSArray<NSDictionary *> *)descriptions NS_SWIFT_NAME(windowIDs(at:in:));

#pragma mark Screen

/**
 *  Returns the screen that the window is most on. The algorithm is area-based such that the screen that contains the most of the window's area is considered to be the window's screen.
 *
 *  @return A NSScreen instance for the screen that the window is most on.
 */
- (nullable NSScreen *)screen;

/**
 *  Moves the window to the given screen.
 *
 *  The window is always positioned at the screen's origin.
 *
 *  @param screen The screen on which the window should be moved to.
 */
- (void)moveToScreen:(NSScreen *)screen;

#pragma mark Space

/**
 *  Moves the window to a given space. The space is provided as a number between 1 and 16, which corresponds to the numerical index of the space defined by Mission Control.
 *
 *  @param space The space on which to move the window.
 */
- (void)moveToSpace:(NSUInteger)space;

/**
 *  Moves the window to a space using the shortcut defined by the provided event.
 *
 *  @param event The event used to switch to a given space.
 */
- (void)moveToSpaceWithEvent:(NSEvent *)event;

#pragma mark Window Actions

/**
 *  Minimize the window.
 */
- (void)minimize;

/**
 *  Unminimize the window.
 */
- (void)unMinimize;

#pragma mark Window Focus

/**
 Perform a raise action without bringing the application into focus.
 @return YES if the window was successfully raised and NO otherwise.
 */
- (BOOL)raiseWindow;

@end

NS_ASSUME_NONNULL_END
