//
//  NSScreen+Silica.h
//  Silica
//

#import <AppKit/AppKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A category defining helper methods on NSScreen that are generally useful for window management.
 */
@interface NSScreen (Silica)

/**
 *  Returns the frame of the screen adjusted to a global coordinate system.
 *
 *  @return The frame of the screen adjusted to a global coordinate system.
 */
- (CGRect)frameIncludingDockAndMenu;

/**
 *  Returns the frame of the screen adjusted to a global coordinate system and adjusted to not include the dock or the menu.
 *
 *  @return The frame of the screen adjusted to a global coordinate system and adjusted to not include the dock or the menu.
 */
- (CGRect)frameWithoutDockOrMenu;

@end

NS_ASSUME_NONNULL_END
