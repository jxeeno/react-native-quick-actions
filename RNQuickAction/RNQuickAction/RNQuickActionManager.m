//
//  RNQuickAction.m
//  RNQuickAction
//
//  Created by Jordan Byron on 9/26/15.
//  Copyright © 2015 react-native. All rights reserved.
//

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RNQuickActionManager.h"
#import "RCTUtils.h"

NSString *const RCTShortcutItemClicked = @"ShortcutItemClicked";

NSDictionary *RNQuickAction(UIApplicationShortcutItem *item) {
    if (!item) return nil;
    return @{
        @"type": item.type,
        @"title": item.localizedTitle,
        @"userInfo": item.userInfo ?: @{}
    };
}

@implementation RNQuickActionManager
{
    UIApplicationShortcutItem *_initialAction;
}

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

- (instancetype)init
{
    if ((self = [super init])) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleQuickActionPress:)
                                                     name:RCTShortcutItemClicked
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setBridge:(RCTBridge *)bridge
{
    _bridge = bridge;
    _initialAction = [bridge.launchOptions[UIApplicationLaunchOptionsShortcutItemKey] copy];
}

// Map user passed array of UIApplicationShortcutItem
- (NSArray*)dynamicShortcutItemsForPassedArray:(NSArray*)passedArray {
    NSDictionary *icons = @{
        @"compose": @(UIApplicationShortcutIconTypeCompose),
        @"play": @(UIApplicationShortcutIconTypePlay),
        @"pause": @(UIApplicationShortcutIconTypePause),
        @"add": @(UIApplicationShortcutIconTypeAdd),
        @"location": @(UIApplicationShortcutIconTypeLocation),
        @"search": @(UIApplicationShortcutIconTypeSearch),
        @"share": @(UIApplicationShortcutIconTypeShare)
    };
    
    NSMutableArray *shortcutItems = [NSMutableArray new];
    
    [passedArray enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        NSString *iconName = item[@"icon"];
        
        // If passed iconName is enum, use system icon
        // Otherwise, load from bundle
        UIApplicationShortcutIcon *shortcutIcon;
        NSNumber *iconType = icons[iconName];
        
        if (iconType) {
            shortcutIcon = [UIApplicationShortcutIcon iconWithType:[iconType intValue]];
        } else if (iconName) {
            shortcutIcon = [UIApplicationShortcutIcon iconWithTemplateImageName:iconName];
        }
        
        [shortcutItems addObject:[[UIApplicationShortcutItem alloc] initWithType:item[@"type"]
                                                                  localizedTitle:item[@"title"] ?: item[@"type"]
                                                               localizedSubtitle:item[@"subtitle"]
                                                                            icon:shortcutIcon
                                                                        userInfo:item[@"userInfo"]]];
    }];
    
    return shortcutItems;
}

RCT_EXPORT_METHOD(setShortcutItems:(NSArray *) shortcutItems)
{
    NSArray *dynamicShortcuts = [self dynamicShortcutItemsForPassedArray:shortcutItems];
    [UIApplication sharedApplication].shortcutItems = dynamicShortcuts;
}

RCT_EXPORT_METHOD(clearShortcutItems)
{
    [UIApplication sharedApplication].shortcutItems = nil;
}

+ (void)onQuickActionPress:(UIApplicationShortcutItem *) shortcutItem completionHandler:(void (^)(BOOL succeeded)) completionHandler
{
    RCTLogInfo(@"[RNQuickAction] Quick action shortcut item pressed: %@", [shortcutItem type]);

    [[NSNotificationCenter defaultCenter] postNotificationName:RCTShortcutItemClicked
                                                        object:self
                                                      userInfo:RNQuickAction(shortcutItem)];

    completionHandler(YES);
}

- (void)handleQuickActionPress:(NSNotification *) notification
{
    [_bridge.eventDispatcher sendDeviceEventWithName:@"quickActionShortcut"
                                                body:notification.userInfo];
}

- (NSDictionary *)constantsToExport
{
    return @{
      @"initialAction": RCTNullIfNil(RNQuickAction(_initialAction))
    };
}

@end