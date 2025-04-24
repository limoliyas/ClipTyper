#import "AppDelegate.h"
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

#define CONFIG_PATH [NSHomeDirectory() stringByAppendingPathComponent:@"/Library/Application Support/ClipTyper/config.json"]

@implementation AppDelegate {
    NSMutableDictionary *config;
    NSMenuItem *zhSpeedItem;
    NSMenuItem *enSpeedItem;
    NSMenuItem *delayItem;
    NSMenuItem *hotkeyItem;
    id _eventMonitor;         // ✅ 加上监听器保存变量
    NSStatusItem *_statusItem; // 使用 _statusItem 来避免与属性冲突
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog(@"🚀 应用启动成功");

    // 加载配置
    [self loadOrInitConfig];

    // 设置菜单栏图标
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

    // 加载图标文件
    NSString *path = [[NSBundle mainBundle] pathForResource:@"logo_menu" ofType:@"png"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSLog(@"❌ 找不到图标文件: %@", path);
    } else {
        NSLog(@"✅ 找到图标文件: %@", path);
    }

    NSImage *icon = [[NSImage alloc] initWithContentsOfFile:path];
    if (icon) {
        [icon setTemplate:NO]; // 设置为模板，适应不同的背景
        _statusItem.button.image = icon; // 使用 button.image 设置菜单栏图标
        NSLog(@"✅ 成功设置菜单栏图标");
    } else {
        NSLog(@"❌ 图标加载失败");
    }

    // 创建菜单
    NSMenu *menu = [[NSMenu alloc] init];

    zhSpeedItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"中文打字速度: %@ms", config[@"zhSpeed"] ?: @"120"]
                                              action:@selector(changeZhSpeed)
                                       keyEquivalent:@""];
    [menu addItem:zhSpeedItem];

    enSpeedItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"英文打字速度: %@ms", config[@"enSpeed"] ?: @"50"]
                                              action:@selector(changeEnSpeed)
                                       keyEquivalent:@""];
    [menu addItem:enSpeedItem];

    delayItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"触发延迟: %@ms", config[@"delay"] ?: @"300"]
                                            action:@selector(changeDelay)
                                     keyEquivalent:@""];
    [menu addItem:delayItem];

    NSUInteger keyCode = [config[@"keyCode"] unsignedIntegerValue];
    NSUInteger modFlags = [config[@"modifierFlags"] unsignedIntegerValue];
    hotkeyItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"快捷键: %@", [self describeHotkeyWithKeyCode:keyCode modifiers:modFlags]]
                                             action:@selector(changeHotkey)
                                      keyEquivalent:@""];
    [menu addItem:hotkeyItem];

    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"退出" action:@selector(quitApp:) keyEquivalent:@"q"];

    _statusItem.menu = menu;

    // 注册快捷键
    [self registerGlobalHotkey];
}

- (void)loadOrInitConfig {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:CONFIG_PATH]) {
        config = [@{
            @"zhSpeed": @"120",
            @"enSpeed": @"50",
            @"delay": @"300",
            @"hotkeyKeyCode": @(35), // P 键
            @"hotkeyModifierFlags": @(NSEventModifierFlagControl | NSEventModifierFlagOption) // ⌃⌥
        } mutableCopy];
        [self saveConfig];
    } else {
        NSData *data = [NSData dataWithContentsOfFile:CONFIG_PATH];
        config = [[NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil] mutableCopy];

        // 确保每个 key 都有值
        if (!config[@"zhSpeed"]) config[@"zhSpeed"] = @"120";
        if (!config[@"enSpeed"]) config[@"enSpeed"] = @"50";
        if (!config[@"delay"]) config[@"delay"] = @"300";


        if (!config[@"keyCode"]) config[@"keyCode"] = @(35); // P 键
        if (!config[@"modifierFlags"]) config[@"modifierFlags"] = @(NSEventModifierFlagControl | NSEventModifierFlagOption);

        [self saveConfig];
    }
    
}

- (void)saveConfig {
    NSData *data = [NSJSONSerialization dataWithJSONObject:config options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:CONFIG_PATH atomically:YES];
}

- (void)changeZhSpeed {
    [self promptForKey:@"zhSpeed" label:@"中文打字速度(ms)" menuItem:zhSpeedItem];
}

- (void)changeEnSpeed {
    [self promptForKey:@"enSpeed" label:@"英文打字速度(ms)" menuItem:enSpeedItem];
}

- (void)changeDelay {
    [self promptForKey:@"delay" label:@"触发延迟(ms)" menuItem:delayItem];
}

- (void)promptForKey:(NSString *)key label:(NSString *)label menuItem:(NSMenuItem *)item {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:label];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    input.stringValue = config[key] ?: @"100";
    [alert setAccessoryView:input];
    [alert addButtonWithTitle:@"确定"];
    [alert addButtonWithTitle:@"取消"];

    if ([alert runModal] == NSAlertFirstButtonReturn) {
        config[key] = input.stringValue;
        [self saveConfig];
        item.title = [NSString stringWithFormat:@"%@: %@ms", label, input.stringValue];
    }
}

- (void)quitApp:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)typeClipboardText {
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSString *text = [pasteboard stringForType:NSPasteboardTypeString];

    if (!text) {
        NSLog(@"⚠️ 剪贴板无文本");
        return;
    }

    for (NSUInteger i = 0; i < [text length]; i++) {
        UniChar c = [text characterAtIndex:i];
        CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateHIDSystemState);
        CGEventRef keyDown = CGEventCreateKeyboardEvent(source, 0, true);
        CGEventRef keyUp = CGEventCreateKeyboardEvent(source, 0, false);

        CGEventKeyboardSetUnicodeString(keyDown, 1, &c);
        CGEventKeyboardSetUnicodeString(keyUp, 1, &c);

        CGEventPost(kCGHIDEventTap, keyDown);
        CGEventPost(kCGHIDEventTap, keyUp);

        CFRelease(keyDown);
        CFRelease(keyUp);
        CFRelease(source);

        BOOL isChinese = (c >= 0x4E00 && c <= 0x9FFF);
        int sleepTime = isChinese ? [config[@"zhSpeed"] intValue] : [config[@"enSpeed"] intValue];
        usleep(sleepTime * 1000);
    }

    NSLog(@"✅ 模拟输入完成");
}

- (void)changeHotkey {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"请按下新的快捷键"];
    [alert setInformativeText:@"按下组合键后，点击确定"];

    NSTextField *displayField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
    displayField.stringValue = [self describeHotkeyWithKeyCode:[config[@"keyCode"] unsignedIntegerValue]
                                                 modifiers:[config[@"modifierFlags"] unsignedIntegerValue]];
    displayField.editable = NO;
    displayField.bezeled = YES;
    displayField.drawsBackground = YES;
    [alert setAccessoryView:displayField];

    __block NSUInteger capturedKeyCode = 0;
    __block NSUInteger capturedModifiers = 0;

    // 🌟 创建一个窗口用于获取焦点
   NSWindow *focusWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 1, 1)
                                                     styleMask:NSWindowStyleMaskBorderless
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
    [focusWindow setReleasedWhenClosed:NO];
    [focusWindow setBackgroundColor:[NSColor clearColor]];
    [focusWindow setOpaque:NO];
    [focusWindow setLevel:NSModalPanelWindowLevel]; // 不干扰主界面
    [focusWindow center];
    [focusWindow makeKeyAndOrderFront:nil];

    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(30, 50, 240, 24)];
    label.stringValue = @"请按下组合键…";
    label.editable = NO;
    label.bordered = NO;
    label.backgroundColor = NSColor.clearColor;

    [focusWindow.contentView addSubview:label];
    [focusWindow.contentView addSubview:displayField];

    // 🌟 显示窗口后，监听事件
    __block BOOL keyCaptured = NO;
    __block id localMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *event) {
        capturedKeyCode = event.keyCode;
        capturedModifiers = event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask;
        NSString *desc = [self describeHotkeyWithKeyCode:capturedKeyCode modifiers:capturedModifiers];
        displayField.stringValue = desc;
        keyCaptured = YES; // 每次都更新
        return event; // 🔁 返回 event 避免类型不匹配
    }];

    // 添加 Enter（回车）键监听器，模拟点击“确定”
    __block id returnKeyMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent * _Nullable(NSEvent *event) {
        if (event.keyCode == 36) { // 回车键
            [NSApp endSheet:focusWindow returnCode:NSAlertFirstButtonReturn];
            return nil;
        }
        return event;
    }];

    // 🌟 创建一个确认框，并绑定到设置窗口
    NSAlert *confirm = [[NSAlert alloc] init];
    [confirm setMessageText:@"使用此快捷键吗？"];
    [confirm setAccessoryView:displayField];
    [confirm addButtonWithTitle:@"确定"];
    [confirm addButtonWithTitle:@"取消"];

    [confirm beginSheetModalForWindow:focusWindow completionHandler:^(NSModalResponse returnCode) {
        [NSEvent removeMonitor:localMonitor];
        [NSEvent removeMonitor:returnKeyMonitor];
        [focusWindow close];

        if (returnCode == NSAlertFirstButtonReturn && keyCaptured) {
            config[@"keyCode"] = @(capturedKeyCode);
            config[@"modifierFlags"] = @(capturedModifiers);
            [self saveConfig];

            hotkeyItem.title = [NSString stringWithFormat:@"快捷键: %@", [self describeHotkeyWithKeyCode:capturedKeyCode modifiers:capturedModifiers]];
            [self registerGlobalHotkey];
        }
    }];
}

- (void)registerGlobalHotkey {
    if (_eventMonitor) {
        [NSEvent removeMonitor:_eventMonitor];
        _eventMonitor = nil;
    }

    NSUInteger keyCode = [config[@"keyCode"] unsignedIntegerValue];
    NSUInteger modFlags = [config[@"modifierFlags"] unsignedIntegerValue];

    _eventMonitor = [NSEvent addGlobalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^(NSEvent *event) {
        if ((event.keyCode == keyCode) &&
            ((event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask) == modFlags)) {
            NSLog(@"🌟 快捷键触发！");
            double delayMs = [config[@"delay"] doubleValue];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayMs * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                [self typeClipboardText];
            });
        }
    }];
}

- (NSString *)describeHotkeyWithKeyCode:(NSUInteger)keyCode modifiers:(NSUInteger)modifiers {
    NSMutableString *desc = [NSMutableString string];

    if (modifiers & NSEventModifierFlagControl) [desc appendString:@"⌃"];
    if (modifiers & NSEventModifierFlagOption)  [desc appendString:@"⌥"];
    if (modifiers & NSEventModifierFlagCommand) [desc appendString:@"⌘"];
    if (modifiers & NSEventModifierFlagShift)   [desc appendString:@"⇧"];

    // 获取当前键盘布局
    TISInputSourceRef source = TISCopyCurrentKeyboardLayoutInputSource();
    CFDataRef layoutData = (CFDataRef)TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData);

    if (layoutData) {
        const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);

        UInt32 deadKeyState = 0;
        UniCharCount maxStringLength = 4;
        UniCharCount actualStringLength = 0;
        UniChar unicodeString[4];

        OSStatus status = UCKeyTranslate(
            keyboardLayout,
            (UInt16)keyCode,
            kUCKeyActionDisplay,
            0, // <== 修改点：不要用 (modifiers >> 16)
            LMGetKbdType(),
            kUCKeyTranslateNoDeadKeysBit,
            &deadKeyState,
            maxStringLength,
            &actualStringLength,
            unicodeString
        );

        if (status == noErr && actualStringLength > 0) {
            NSString *keyStr = [NSString stringWithCharacters:unicodeString length:1];
            [desc appendString:[keyStr uppercaseString]];
        } else {
            [desc appendString:@"?"];
        }
    } else {
        [desc appendString:@"?"];
    }

    if (source) CFRelease(source);

    return desc;
}



@end