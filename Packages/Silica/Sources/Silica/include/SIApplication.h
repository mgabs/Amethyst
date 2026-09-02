//
//  SIApplication.h
//  Silica
//

#import <AppKit/AppKit.h>
#import "SIAccessibilityElement.h"
#import "SIWindow.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Block type for the handling of accessibility notifications.
 *
 *  @param accessibilityElement The accessibility element that the accessibility notification pertains to. Will always be an element either owned by the application or the application itself.
 */
typedef void (^SIAXNotificationHandler)(SIAccessibilityElement *accessibilityElement);

/**
 *  Accessibility wrapper for application elements.
 */
@interface SIApplication : SIAccessibilityElement

/**
 *  Attempts to construct an accessibility wrapper from an NSRunningApplication instance.
 *
 *  @param runningApplication A running application in the shared workspace.
 *
 *  @return A SIApplication instance if an accessibility element could be constructed from the running application instance. Returns nil otherwise.
 */
+ (instancetype)applicationWithRunningApplication:(NSRunningApplication *)runningApplication;

/**
 *  Registers a notification handler for an accessibility notification.
 *
 *  Note that a strong reference to the handler is maintained, so any memory captured by the block will not be released until the notification handler is unregistered by calling unobserveNotification:withElement:
 *
 *  @param notification         The notification to register a handler for.
 *  @param accessibilityElement The accessibility element associated with the notification. Must be an element owned by the application or the application itself.
 *  @param handler              A block to be called when the notification is received for the accessibility element.
 *  @return kAXErrorSuccess if the observer was added, otherwise the AXError from the accessibility API.
 */
- (AXError)observeNotification:(CFStringRef)notification withElement:(SIAccessibilityElement *)accessibilityElement handler:(SIAXNotificationHandler)handler;

/**
 *  Unregisters a notification handler for an accessibility notification.
 *
 *  If a notification handler was previously registered for the notification and accessibility element the application will unregister the notification handler and release its reference to the handler block and any captured state therein.
 *
 *  @param notification         The notification to unregister a handler for.
 *  @param accessibilityElement The accessibility element associated with the notification. Must be an element owned by the application or the application itself.
 */
- (void)unobserveNotification:(CFStringRef)notification withElement:(SIAccessibilityElement *)accessibilityElement;

/**
 *  Returns an array of SIWindow objects for all windows in the application.
 *
 *  @return An array of SIWindow objects for all windows in the application.
 */
- (NSArray<SIWindow *> *)windows;

/**
 *  Returns the title of the application.
 *
 *  @return The title of the application.
 */
- (nullable NSString *)title;

/**
 *  Drops any cached windows so that the windows returned by a call to windows will be representative of the most up to date state of the application.
 */
- (void)dropWindowsCache;

@end

NS_ASSUME_NONNULL_END
