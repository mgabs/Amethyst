//
//  SIWindow.m
//  Silica
//

#import "SIWindow.h"

#import <Carbon/Carbon.h>
#import "CGSInternal/CGSConnection.h"
#import "CGSInternal/CGSHotKeys.h"
#import "CGSInternal/CGSSpace.h"
#import "NSScreen+Silica.h"
#import "SIApplication.h"
#import "SISystemWideElement.h"

AXError _AXUIElementGetWindow(AXUIElementRef element, CGWindowID *idOut);

@interface SIWindow ()
@property (nonatomic, assign) CGWindowID _windowID;
@end

@implementation SIWindow

#pragma mark Window Accessors

+ (SIWindow *)focusedWindow {
    if (!AXIsProcessTrustedWithOptions(NULL)) return nil;

    CFTypeRef applicationRef = NULL;
    AXError error = AXUIElementCopyAttributeValue([SISystemWideElement systemWideElement].axElementRef, kAXFocusedApplicationAttribute, &applicationRef);
    if (error != kAXErrorSuccess || !applicationRef) return nil;

    CFTypeRef windowRef = NULL;
    error = AXUIElementCopyAttributeValue(applicationRef, (CFStringRef)NSAccessibilityFocusedWindowAttribute, &windowRef);
    CFRelease(applicationRef);
    if (error != kAXErrorSuccess || !windowRef) return nil;

    SIWindow *window = [[SIWindow alloc] initWithAXElement:windowRef];
    CFRelease(windowRef);

    if ([window isSheet]) {
        SIAccessibilityElement * __attribute__((objc_precise_lifetime)) parent = [window elementForKey:kAXParentAttribute];
        if (parent) {
            return [[SIWindow alloc] initWithAXElement:parent.axElementRef];
        }
    }

    return window;
}

#pragma mark Window Properties

- (CGWindowID)windowID {
    if (self._windowID == kCGNullWindowID) {
        CGWindowID windowID;
        AXError error = _AXUIElementGetWindow(self.axElementRef, &windowID);
        if (error != kAXErrorSuccess) {
            return kCGNullWindowID;
        }
        
        self._windowID = windowID;
    }
    
    return self._windowID;
}

- (NSString *)title {
    return [self stringForKey:kAXTitleAttribute];
}

- (NSString *)role {
    return [self stringForKey:kAXRoleAttribute];
}

- (NSString *)subrole {
    return [self stringForKey:kAXSubroleAttribute];
}

- (BOOL)isWindowMinimized {
    return [[self numberForKey:kAXMinimizedAttribute] boolValue];
}

- (BOOL)isNormalWindow {
    return [[self subrole] isEqualToString:(__bridge NSString *)kAXStandardWindowSubrole];
}

- (BOOL)isSheet {
    return [[self stringForKey:kAXRoleAttribute] isEqualToString:(__bridge NSString *)kAXSheetRole];
}

- (BOOL)isActive {
    if ([[self numberForKey:kAXHiddenAttribute] boolValue]) return NO;
    if ([[self numberForKey:kAXMinimizedAttribute] boolValue]) return NO;
    return YES;
}

- (BOOL)isOnScreen {
    if (!self.isActive) return NO;
    return [[SIWindow onScreenWindowIDs] containsObject:@(self.windowID)];
}

#pragma mark Window Server Queries

- (CGSSpaceID)managedSpaceID {
    CGWindowID windowID = self.windowID;
    if (windowID == kCGNullWindowID) return 0;

    CFArrayRef spaces = CGSCopySpacesForWindows(CGSMainConnectionID(), kCGSAllSpacesMask, (__bridge CFArrayRef)@[@(windowID)]);
    if (!spaces) return 0;

    NSArray<NSNumber *> *spaceIDs = CFBridgingRelease(spaces);
    return spaceIDs.count > 0 ? spaceIDs.firstObject.unsignedLongValue : 0;
}

+ (NSArray<NSDictionary *> *)onScreenWindowDescriptions {
    CFArrayRef descriptions = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    if (!descriptions) return @[];
    return CFBridgingRelease(descriptions);
}

+ (NSSet<NSNumber *> *)onScreenWindowIDs {
    NSMutableSet<NSNumber *> *ids = [NSMutableSet set];
    for (NSDictionary *description in [self onScreenWindowDescriptions]) {
        NSNumber *windowID = description[(__bridge NSString *)kCGWindowNumber];
        if (windowID) [ids addObject:windowID];
    }
    return ids;
}

+ (NSArray<NSNumber *> *)onScreenWindowIDsAtPoint:(CGPoint)point {
    return [self windowIDsAtPoint:point inDescriptions:[self onScreenWindowDescriptions]];
}

+ (NSArray<NSNumber *> *)windowIDsAtPoint:(CGPoint)point inDescriptions:(NSArray<NSDictionary *> *)descriptions {
    NSMutableArray<NSNumber *> *ids = [NSMutableArray array];
    for (NSDictionary *description in descriptions) {
        NSNumber *windowID = description[(__bridge NSString *)kCGWindowNumber];
        NSDictionary *boundsDictionary = description[(__bridge NSString *)kCGWindowBounds];
        CGRect bounds;
        if (!windowID || ![boundsDictionary isKindOfClass:[NSDictionary class]]) continue;
        if (!CGRectMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)boundsDictionary, &bounds)) continue;
        if (CGRectContainsPoint(bounds, point)) [ids addObject:windowID];
    }
    return ids;
}

#pragma mark Screen

- (NSScreen *)screen {
    CGRect windowFrame = [self frame];
    
    CGFloat lastVolume = 0;
    NSScreen *lastScreen = nil;
    
    for (NSScreen *screen in [NSScreen screens]) {
        CGRect screenFrame = [screen frameIncludingDockAndMenu];
        CGRect intersection = CGRectIntersection(windowFrame, screenFrame);
        CGFloat volume = intersection.size.width * intersection.size.height;
        
        if (volume > lastVolume) {
            lastVolume = volume;
            lastScreen = screen;
        }
    }
    
    return lastScreen;
}

- (void)moveToScreen:(NSScreen *)screen {
    self.position = screen.frameWithoutDockOrMenu.origin;
}

#pragma mark Space

- (void)moveToSpace:(NSUInteger)space {
    NSEvent *event = [SISystemWideElement eventForSwitchingToSpace:space];
    if (event == nil) return;
    
    [self moveToSpaceWithEvent:event];
}

- (void)moveToSpaceWithEvent:(NSEvent *)event {
    SIAccessibilityElement *minimizeButtonElement = [self elementForKey:kAXMinimizeButtonAttribute];
    CGRect minimizeButtonFrame = minimizeButtonElement.frame;
    CGRect windowFrame = self.frame;

    CGPoint mouseCursorPoint = {
        .x = (minimizeButtonElement ? CGRectGetMidX(minimizeButtonFrame) : windowFrame.origin.x + 5.0),
        .y = windowFrame.origin.y + fabs(windowFrame.origin.y - CGRectGetMinY(minimizeButtonFrame)) / 2.0
    };

    CGEventRef mouseMoveEvent = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, mouseCursorPoint, kCGMouseButtonLeft);
    CGEventRef mouseDragEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDragged, mouseCursorPoint, kCGMouseButtonLeft);
    CGEventRef mouseDownEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseDown, mouseCursorPoint, kCGMouseButtonLeft);
    CGEventRef mouseUpEvent = CGEventCreateMouseEvent(NULL, kCGEventLeftMouseUp, mouseCursorPoint, kCGMouseButtonLeft);
    
    CGEventSetFlags(mouseMoveEvent, 0);
    CGEventSetFlags(mouseDownEvent, 0);
    CGEventSetFlags(mouseUpEvent, 0);

    // Move the mouse into place at the window's toolbar
    CGEventPost(kCGHIDEventTap, mouseMoveEvent);
    // Mouse down to set up the drag
    CGEventPost(kCGHIDEventTap, mouseDownEvent);
    // Drag event to grab hold of the window
    CGEventPost(kCGHIDEventTap, mouseDragEvent);

    // Make a slight delay to make sure the window is grabbed
    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        // Send the shortcut command to get Mission Control to switch spaces from under the window
        [SISystemWideElement switchToSpaceWithEvent:event];
        
        // Make a slight delay to finish the space transition animation
        double delayInSeconds = 0.4;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            // Let go of the window.
            CGEventPost(kCGHIDEventTap, mouseUpEvent);
            CFRelease(mouseUpEvent);
        });
    });

    CFRelease(mouseMoveEvent);
    CFRelease(mouseDownEvent);
}

#pragma mark Window Actions

- (void)minimize {
    [self setWindowMinimized:YES];
}

- (void)unMinimize {
    [self setWindowMinimized:NO];
}

- (void)setWindowMinimized:(BOOL)flag {
    [self setWindowProperty:NSAccessibilityMinimizedAttribute withValue:@(flag)];
}

- (BOOL)setWindowProperty:(NSString *)propType withValue:(id)value {
    if ([value isKindOfClass:[NSNumber class]]) {
        AXError result = AXUIElementSetAttributeValue(self.axElementRef, (__bridge CFStringRef)(propType), (__bridge CFTypeRef)(value));
        if (result == kAXErrorSuccess)
            return YES;
    }
    return NO;
}

#pragma mark Window Focus

- (BOOL)raiseWindow {
    AXError error = AXUIElementPerformAction(self.axElementRef, kAXRaiseAction);
    if (error != kAXErrorSuccess) {
        return NO;
    }

    return YES;
}

@end
