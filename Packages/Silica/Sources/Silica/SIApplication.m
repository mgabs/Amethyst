//
//  SIApplication.m
//  Silica
//

#import "SIApplication.h"

#import <AppKit/AppKit.h>
#import "SIWindow.h"
#import "SIUniversalAccessHelper.h"

@interface SIApplicationObservation : NSObject
@property (nonatomic, strong) NSString *notification;
@property (nonatomic, copy) SIAXNotificationHandler handler;
@end

@implementation SIApplicationObservation
@end

@interface SIApplication ()
@property (nonatomic, assign) AXObserverRef observerRef;
@property (nonatomic, strong) NSMutableDictionary *elementToObservations;

@property (nonatomic, strong) NSMutableArray *cachedWindows;
@end

@implementation SIApplication

#pragma mark Lifecycle

+ (instancetype)applicationWithRunningApplication:(NSRunningApplication *)runningApplication {
    AXUIElementRef axElementRef = AXUIElementCreateApplication(runningApplication.processIdentifier);
    SIApplication *application = [[SIApplication alloc] initWithAXElement:axElementRef];
    CFRelease(axElementRef);
    return application;
}

+ (NSArray *)runningApplications {
    if (![SIUniversalAccessHelper isAccessibilityTrusted])
        return nil;

    NSMutableArray *apps = [NSMutableArray array];

    for (NSRunningApplication *runningApp in [[NSWorkspace sharedWorkspace] runningApplications]) {
        SIApplication *app = [SIApplication applicationWithRunningApplication:runningApp];
        [apps addObject:app];
    }

    return apps;
}

- (void)dealloc {
    if (_observerRef) {
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(_observerRef), kCFRunLoopDefaultMode);
        for (SIAccessibilityElement *element in self.elementToObservations.allKeys) {
            for (SIApplicationObservation *observation in self.elementToObservations[element]) {
                AXObserverRemoveNotification(_observerRef, element.axElementRef, (__bridge CFStringRef)observation.notification);
            }
        }
        CFRunLoopSourceInvalidate(AXObserverGetRunLoopSource(_observerRef));
        CFRelease(_observerRef);
    }
}

#pragma mark AXObserver

void observerCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    SIAXNotificationHandler callback = (__bridge SIAXNotificationHandler)refcon;
    SIWindow *window = [[SIWindow alloc] initWithAXElement:element];
    callback(window);
}

- (AXError)observeNotification:(CFStringRef)notification withElement:(SIAccessibilityElement *)accessibilityElement handler:(SIAXNotificationHandler)handler {
    if (!self.observerRef) {
        AXObserverRef observerRef;
        AXError error = AXObserverCreate(self.processIdentifier, &observerCallback, &observerRef);

        if (error != kAXErrorSuccess) return error;

        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observerRef), kCFRunLoopDefaultMode);

        self.observerRef = observerRef;
        self.elementToObservations = [NSMutableDictionary dictionaryWithCapacity:1];
    }

    // The refcon must outlive the registration, so copy the block first and hand
    // the copy to both the observer and the bookkeeping record.
    SIAXNotificationHandler handlerCopy = [handler copy];
    AXError error = AXObserverAddNotification(self.observerRef, accessibilityElement.axElementRef, notification, (__bridge void *)handlerCopy);

    if (error == kAXErrorNotificationAlreadyRegistered) {
        // Replace the stale registration so the handler passed now is the one that fires.
        // If the re-add fails the notification is left unregistered; callers retry.
        AXObserverRemoveNotification(self.observerRef, accessibilityElement.axElementRef, notification);
        error = AXObserverAddNotification(self.observerRef, accessibilityElement.axElementRef, notification, (__bridge void *)handlerCopy);
    }

    if (error != kAXErrorSuccess) {
        return error;
    }

    SIApplicationObservation *observation = [[SIApplicationObservation alloc] init];
    observation.notification = (__bridge NSString *)notification;
    observation.handler = handlerCopy;

    NSMutableArray<SIApplicationObservation *> *observations = self.elementToObservations[accessibilityElement];
    if (!observations) {
        observations = [NSMutableArray array];
        self.elementToObservations[accessibilityElement] = observations;
    }
    // A re-add above replaced any earlier registration for this notification, so drop its record.
    [observations filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SIApplicationObservation *existing, NSDictionary *bindings) {
        return ![existing.notification isEqualToString:(__bridge NSString *)notification];
    }]];
    [observations addObject:observation];

    return error;
}

- (void)unobserveNotification:(CFStringRef)notification withElement:(SIAccessibilityElement *)accessibilityElement {
    if (!self.observerRef) return;

    NSMutableArray<SIApplicationObservation *> *remaining = [NSMutableArray array];
    for (SIApplicationObservation *observation in self.elementToObservations[accessibilityElement]) {
        AXError error = AXObserverRemoveNotification(self.observerRef, accessibilityElement.axElementRef, (__bridge CFStringRef)observation.notification);
        BOOL removed = error == kAXErrorSuccess
            || error == kAXErrorNotificationNotRegistered
            || error == kAXErrorInvalidUIElement;
        if (!removed) {
            // The registration is still live; keep its handler alive so the refcon stays valid.
            [remaining addObject:observation];
        }
    }

    if (remaining.count > 0) {
        self.elementToObservations[accessibilityElement] = remaining;
    } else {
        [self.elementToObservations removeObjectForKey:accessibilityElement];
    }

    if (self.elementToObservations.count == 0) {
        CFRunLoopSourceRef source = AXObserverGetRunLoopSource(self.observerRef);
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, kCFRunLoopDefaultMode);
        CFRunLoopSourceInvalidate(source);
        CFRelease(self.observerRef);
        self.observerRef = NULL;
    }
}

#pragma mark Public Accessors

- (NSArray *)windows {
    if (!self.cachedWindows) {
        self.cachedWindows = [NSMutableArray array];
        NSArray *windowRefs = [self arrayForKey:kAXWindowsAttribute];
        for (NSUInteger index = 0; index < windowRefs.count; ++index) {
            AXUIElementRef windowRef = (__bridge AXUIElementRef)windowRefs[index];
            SIWindow *window = [[SIWindow alloc] initWithAXElement:windowRef];

            [self.cachedWindows addObject:window];
        }
    }
    return self.cachedWindows;
}

- (NSArray *)visibleWindows {
    return [self.windows filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SIWindow *window, NSDictionary *bindings) {
        return ![[window app] isHidden] && ![window isWindowMinimized] && [window isNormalWindow];
    }]];
}

- (NSString *)title {
    return [self stringForKey:kAXTitleAttribute];
}

- (BOOL)isHidden {
    return [[self numberForKey:kAXHiddenAttribute] boolValue];
}

- (void)hide {
    [[NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier] hide];
}

- (void)unhide {
    [[NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier] unhide];
}

- (void)kill {
    [[NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier] terminate];
}

- (void)kill9 {
    [[NSRunningApplication runningApplicationWithProcessIdentifier:self.processIdentifier] forceTerminate];
}

- (void)dropWindowsCache {
    self.cachedWindows = nil;
}

@end
