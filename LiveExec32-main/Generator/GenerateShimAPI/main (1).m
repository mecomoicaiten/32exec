@import Darwin;
@import QuartzCore;
@import CoreFoundation;
@import Foundation;
@import UIKit;
@import ObjectiveC;

#define STRUCT_CGAffineTransform 0x6e6966664147437b
#define STRUCT_CGPoint 0x746e696f5047437b
#define STRUCT_CGRect 0x3d7463655247437b
#define STRUCT_CGSize 0x3d657a695347437b
#define STRUCT_UIEdgeInsets 0x496567644549557b

#define CLS(name) objc_getClass(#name)
#define printNS(...) printf("%s\n", [NSString stringWithFormat:__VA_ARGS__].UTF8String)

@interface FLEXMethod : NSObject
@property(nonatomic, assign, readonly) char *returnType;
@property(nonatomic, assign, readonly) SEL selector;
@property(nonatomic, assign, readonly) NSMethodSignature *signature;
@property(nonatomic, assign, readonly) NSUInteger numberOfArguments;
@property(nonatomic, assign, readonly) NSString *selectorString;
@property(nonatomic, assign, readonly) BOOL isInstanceMethod;
@property(nonatomic, assign, readonly) NSString *imagePath;
+ (id)method:(Method)method isInstanceMethod:(BOOL)isInstanceMethod;
- (NSArray<NSString *>*)prettyArgumentComponents;
@end

@interface FLEXRuntimeUtility : NSObject
+ (NSString *)readableTypeForEncoding:(NSString *)encodingString;
@end

@interface MethodParameter : NSObject
@property(nonatomic, retain) NSString *name;
@property(nonatomic, retain) NSString *type;
@property(nonatomic, assign) const char *signature;
// index from 0
@property(nonatomic) int index;
@end
@implementation MethodParameter

// FIXME: will need to parse header to return correctly. On 64bit, NS*Integer and CGFloat are not distinguishable from 32bit
+ (NSString *)readableTypeForSignature:(const char *)signature {
    // Correct some 32bit types
    switch(signature[0]) {
        case 'c':
            return @"char";
        //case 'Q':
            //return @"unsigned long long";
        //case 'd':
            //return @"double";
        //case 'q':
            //return @"long long";
        default:
            return [CLS(FLEXRuntimeUtility) readableTypeForEncoding:@(signature)];
    }
}

+ (BOOL)isDirectCastType:(char)c {
    switch(c) {
        case 'B':
        case 'C':
        case 'I':
        case 'L':
        case 'Q':
        case 'S':
        case 'b':
        case 'c':
        case 'i':
        case 'l':
        case 'q':
        case 's':
            return YES;
    }
    return NO;
}

+ (BOOL)isFloatingType:(char)c {
    return c == 'd'|| c == 'f';
}

- (instancetype)initWithIndex:(int)index name:(NSString *)name type:(NSString *)type signature:(const char *)signature {
    self = [super init];
    self.index = index;
    self.name = name;
    self.type = type;
    self.signature = signature;
    return self;
}

- (NSString *)declarationInMethod {
    if ([self.type isEqualToString:@"_NSZone *"]) {
        return [NSString stringWithFormat:@"%@:(struct %@)guest_arg%d", self.name, self.type, self.index];
    }
    return [NSString stringWithFormat:@"%@:(%@)guest_arg%d", self.name, self.type, self.index];
}

- (NSString *)declaration {
    if([MethodParameter isDirectCastType:self.signature[0]]) {
        return [NSString stringWithFormat:@"uint64_t host_arg%1$d = (uint64_t)guest_arg%1$d;", self.index];
    } else if([MethodParameter isFloatingType:self.signature[0]]) {
        return [NSString stringWithFormat:@"double host_arg%1$d = (double)guest_arg%1$d;", self.index];
    }
    switch(self.signature[0]) {
        case '@':
        case '#':
            return [NSString stringWithFormat:@"uint64_t host_arg%1$d = [guest_arg%1$d host_self];", self.index];
        case ':':
            return [NSString stringWithFormat:@"uint64_t host_arg%1$d = LC32GetHostSelector(guest_arg%1$d);", self.index];
        case '^':
            if(self.signature[1] == '@' || [MethodParameter isDirectCastType:self.signature[1]]) {
                return [NSString stringWithFormat:@"uint64_t host_arg%d; // %@", self.index, self.type];
            } else if ([self.type isEqualToString:@"_NSZone *"]) {
                return [NSString stringWithFormat:@"uint64_t host_arg%d = 0;", self.index];
            }
            // FIXME ???? else if([MethodParameter isFloatingType:self.signature[0]]) {
            break;
        case 'r': // const
            switch(self.signature[1]) {
                case '*':
                    return [NSString stringWithFormat:@"uint64_t host_arg%1$d = LC32GuestToHostCString(guest_arg%1$d, 0);", self.index];
                //case 'v':
                //    return [NSString stringWithFormat:@"uint64_t host_arg%1$d = 0; // FIXME: LC32GuestToHostCBuffer(guest_arg%1$d, length?);", self.index]; // FIXME
            }
    }

    // structs
    switch(*(uint64_t*)self.signature) {
        case STRUCT_CGAffineTransform:
        case STRUCT_CGPoint:
        case STRUCT_CGRect:
        case STRUCT_CGSize:
        case STRUCT_UIEdgeInsets:
            return [NSString stringWithFormat:@"%1$@_64 host_arg%2$d = LC32Host%1$@(guest_arg%2$d);", self.type, self.index];
            //return [NSString stringWithFormat:@"%1$@_64 host_arg%2$d_value = LC32Host%1$@(guest_arg%2$d); uint64_t host_arg%2$d = LC32GuestToHostCString((const char *)&host_arg%2$d_value, sizeof(host_arg%2$d_value));", self.type, self.index];
    }

    return [NSString stringWithFormat:@"/* %s: unhandled type %@ */", sel_getName(_cmd), self.type];
}

- (NSString *)parameterToBePassed {
    BOOL returnDirect, returnPointer;
    switch(self.signature[0]) {
        case '@':
        case '#':
        case ':':
            returnDirect = YES;
            break;
        case '^':
            returnPointer = self.signature[1] == '@' || [MethodParameter isDirectCastType:self.signature[1]];
            returnDirect |= [self.type isEqualToString:@"_NSZone *"];
            break;
        case 'r':
            // const char *, void too?
            returnDirect = self.signature[1] == '*';
            break;
        default:
            returnDirect = [MethodParameter isDirectCastType:self.signature[0]] || [MethodParameter isFloatingType:self.signature[0]];
            break;
    }

    // structs
    switch(*(uint64_t*)self.signature) {
        case STRUCT_CGAffineTransform:
        case STRUCT_CGPoint:
        case STRUCT_CGRect:
        case STRUCT_CGSize:
        case STRUCT_UIEdgeInsets:
            returnDirect = YES;
            break;
    }

    if(returnDirect) {
        return [NSString stringWithFormat:@"host_arg%d", self.index];
    } else if(returnPointer) {
        return [NSString stringWithFormat:@"&host_arg%d", self.index];
    }
    return [NSString stringWithFormat:@"/* %s: unhandled type %@ */", sel_getName(_cmd), self.type];
}

- (NSString *)postCall {
    switch(self.signature[0]) {
        case 'r':
            switch(self.signature[1]) {
                case '*':
                    // the string might have been copied, in this case invoke back to the host to free them just in case
                    return [NSString stringWithFormat:@"LC32GuestToHostCStringFree(host_arg%1$d);", self.index];
                //default: fallthrough
            }
        case '*':
            // Handle char *modification??
            return [NSString stringWithFormat:@"/* %s: unhandled type %@ */", sel_getName(_cmd), self.type];
        //case '{':
        //    return [NSString stringWithFormat:@"LC32GuestToHostCStringFree(host_arg%1$d);", self.index];
        case '^':
            // handle it below
            if(![self.type isEqualToString:@"_NSZone *"]) {
                break;
            }
            // NSZone: fallthough
        default:
            return [NSString stringWithFormat:@"// No post-process for guest_arg%d", self.index];
    }
    switch(self.signature[1]) {
        case '@': // id **
        case '#': // class **
            return [NSString stringWithFormat:@"*guest_arg%1$d = LC32HostToGuestObject(host_arg%1$d);", self.index];
        default:
            // int*, float *, etc
            if([MethodParameter isDirectCastType:self.signature[1]]) {
                return [NSString stringWithFormat:@"*guest_arg%1$d = (%2$@)host_arg%1$d;", self.index, [self.type substringToIndex:self.type.length-2]];
            }
            break;
    }
    return [NSString stringWithFormat:@"/* %s: unhandled type %@ */", sel_getName(_cmd), self.type];
}

- (NSString *)description {
    return self.declarationInMethod;
}
@end

@interface MethodBuilder : NSObject
@property(nonatomic, retain) FLEXMethod *method;
@property(nonatomic, retain) NSString *returnType;
@property(nonatomic, retain) NSMutableArray<MethodParameter *> *parameters;
@property(nonatomic, retain) NSMutableArray<NSString *> *lines;
@property(nonatomic) BOOL skip;
@end
@implementation MethodBuilder

- (instancetype)initWithMethod:(FLEXMethod *)method {
    self = [super init];
    self.lines = [NSMutableArray new];
    self.parameters = [NSMutableArray new];
    self.method = method;
    self.returnType = [MethodParameter readableTypeForSignature:(self.method.returnType ?: "")];

    SEL selector = method.selector;
    NSArray<NSString *> *selectorParameters = [@(sel_getName(selector)) componentsSeparatedByString:@":"];
    for(int i = 2; i < self.method.numberOfArguments; i++) {
        const char *argType = [self.method.signature getArgumentTypeAtIndex:i] ?: "?";
        NSString *arg = [MethodParameter readableTypeForSignature:argType];
        [self.parameters addObject:[[MethodParameter alloc] initWithIndex:i-2 name:selectorParameters[i-2] type:arg signature:argType]];
    }

    // declare method
    //[self.lines addObject:[NSString stringWithFormat:@"// %@", self.method.description]];
    [self.lines addObject:[NSString stringWithFormat:@"%@ {", self.prettyName]];

    // debug: log calls
    [self.lines addObject:@"  printf(\"DBG: call [%s %s]\\n\", class_getName(self.class), sel_getName(_cmd));"];

    // pull host selector
    [self.lines addObject:[NSString stringWithFormat:@"  static uint64_t _host_cmd;"]];
    [self.lines addObject:[NSString stringWithFormat:@"  if(!_host_cmd) _host_cmd = LC32GetHostSelector(_cmd) | (uint64_t)%d << 63;", self.method.returnType[0] == '{']];

    // pull host objects
    NSMutableString *methodDeclaration = [NSMutableString new];
    for(MethodParameter *param in self.parameters) {
        [self.lines addObject:[NSString stringWithFormat:@"  %@ ", param.declaration]];
    }

    // perform selector
    [self.lines addObject:[NSString stringWithFormat:@"  %@", self.callLine]];

    // post-call: eg set NSError pointer
    for(MethodParameter *param in self.parameters) {
        [self.lines addObject:[NSString stringWithFormat:@"  %@ ", param.postCall]];
    }

    // Return value
    [self.lines addObject:[NSString stringWithFormat:@"  %@", self.returnLine]];

    // End
    [self.lines addObject:@"}"];

    if([self.description containsString:@"unhandled type"]) {
        [self.lines insertObject:@"#if 0 // FIXME: has unhandled types" atIndex:0];
        [self.lines addObject:@"#endif"];
    }
    return self;
}

- (NSString *)prettyName {
    NSString *methodTypeString = self.method.isInstanceMethod ? @"-" : @"+";
    NSString *prettyName = [NSString stringWithFormat:@"%@ (%@)", methodTypeString, self.returnType];

    if (self.method.numberOfArguments > 2) {
        return [prettyName stringByAppendingString:[self.parameters componentsJoinedByString:@" "]];
    } else {
        return [prettyName stringByAppendingString:self.method.selectorString];
    }
}

- (NSString *)callLine {
    NSMutableString *call = [NSMutableString new];
    if(self.method.returnType[0] == '{') {
        [call appendFormat:@"%@_64 host_ret; LC32InvokeHostSelector(self.host_self, _host_cmd, &host_ret, sizeof(host_ret)", self.returnType];
    } else {
        [call appendString:@"uint64_t host_ret = LC32InvokeHostSelector(self.host_self, _host_cmd"];
    }
    for(MethodParameter *param in self.parameters) {
        [call appendFormat:@", %@", param.parameterToBePassed];
    }
    [call appendString:@");"];
    return call;
}

- (NSString *)returnLine {
    switch(self.method.returnType[0]) {
        case 'v':
            if([self.method.selectorString isEqualToString:@"dealloc"]) {
                return @"[super dealloc];";
            } else {
                return @"// return void";
            }
        case '@':
        case '#':
            if([self.method.selectorString hasPrefix:@"init"]) {// init, initWith*
                return @"self.host_self = host_ret; return self;";
            } else {
                return @"return LC32HostToGuestObject(host_ret);";
            }
        case 'B':
        case 'C':
        case 'I':
        case 'L':
        case 'Q':
        case 'S':
        case 'b':
        case 'c':
        case 'd':
        case 'f':
        case 'i':
        case 'l':
        case 'q':
        case 's':
            return [NSString stringWithFormat:@"return (%@)host_ret;", self.returnType];
    }
    
    // structs
    switch(*(uint64_t*)self.method.returnType) {
        case STRUCT_CGAffineTransform:
        case STRUCT_CGPoint:
        case STRUCT_CGRect:
        case STRUCT_CGSize:
        case STRUCT_UIEdgeInsets:
            return [NSString stringWithFormat:@"return LC32Guest%@(host_ret);", self.returnType];
    }

    return [NSString stringWithFormat:@"/* %s: unhandled type %@ */", sel_getName(_cmd), self.returnType];
}

- (NSString *)description {
    return [self.lines componentsJoinedByString:@"\n"];
}
@end

@interface ClassBuilder : NSObject
@property(nonatomic, retain) NSMutableDictionary<NSString *, MethodBuilder *> *methods;
@property(nonatomic) Class cls;
@property(nonatomic, retain) NSString *imagePath;
@end
@implementation ClassBuilder
- (instancetype)initWithClass:(Class)class {
    self = [super init];
    self.cls = class;
    self.methods = [NSMutableDictionary new];

    unsigned int mc = 0;
    Method *mlist;

    mlist = class_copyMethodList(object_getClass(class), &mc);
    for(int m = 0; m < mc; m++) {
        [self validateAndAddMethod:mlist[m] isInstanceMethod:NO];
    }
    free(mlist);

    mlist = class_copyMethodList(class, &mc);
    for(int m = 0; m < mc; m++) {
        [self validateAndAddMethod:mlist[m] isInstanceMethod:YES];
    }
    free(mlist);

    return self;
}

- (instancetype)initWithClassDictionary:(NSDictionary *)dict {
    self = [super init];
    self.methods = [NSMutableDictionary new];

    
}

- (void)validateAndAddMethod:(Method)objcMethod isInstanceMethod:(BOOL)isInstanceMethod {
    SEL selector = method_getName(objcMethod);
    const char *selectorName = sel_getName(selector);
    if(strchr(selectorName, '_') != NULL) {
        // this is a private API, skip
        printNS(@"// Skipped private method: %s", selectorName);
        return;
    } else if(!strncmp(selectorName, "allocWithZone:", 14)) {
        // skip alloc
        printNS(@"// Skipped alloc method: %s", selectorName);
        return;
    }

    FLEXMethod *method = [CLS(FLEXMethod) method:objcMethod isInstanceMethod:isInstanceMethod];
    if(sel_getName(@selector(initialize)) == selectorName) {
        // For +(void)initialize, we must first obtain the host class pointer
        NSMutableString *string = [NSMutableString new];
        [string appendFormat:@"%@ {\n", method.description];
        //[string appendString:@"  self.host_self = LC32GetHostClass(class_getName(self.class));\n"];
        [string appendFormat:@"}"];
        self.methods[method.description] = (id)string;
        return;
    }

    if(!self.imagePath) {
        self.imagePath = [NSBundle bundleForClass:self.cls].executablePath;
    }
    if ([self.imagePath hasSuffix:@"/UIKitCore"] || [self.imagePath hasSuffix:@"/UIFoundation"]) {
        self.imagePath = @"/System/Library/Frameworks/UIKit.framework/UIKit";
    }
/*
    if(method.imagePath != self.imagePath) {
        // this is a category method, skip
        printNS(@"// Skipped category method: %s", selectorName);
        return;
    }
*/
    self.methods[method.description] = [[MethodBuilder alloc] initWithMethod:method];
}

- (NSString *)description {
    NSMutableString *string = [NSMutableString new];
    [string appendString:@"// Generated file\n"];
    [string appendFormat:@"#import <%1$@/%1$@.h>\n", self.imagePath.lastPathComponent];
    [string appendFormat:@"#import <CoreGraphics/CoreGraphics+LC32.h>\n"];
    [string appendFormat:@"#import <UIKit/UIKit+LC32.h>\n"];
    [string appendFormat:@"#import <LC32/LC32.h>\n"];
    [string appendFormat:@"@implementation %@\n", self.cls.description];
    [string appendString:[self.methods.allValues componentsJoinedByString:@"\n\n"]];
    [string appendString:@"\n"];
    [string appendString:@"@end"];
    return string;
}
@end

int main(int argc, char **argv) {
/*
    if(argc != 2) {
        printf("Usage: %s ClassName\n", argv[0]);
        return 1;
    }
    Class cls = objc_getClass(argv[1]);
    if(!cls) {
        printf("Class %s not found\n", argv[1]);
        return 1;
    }
*/
    dlopen("/var/jb/usr/lib/TweakInject/libFLEX.dylib", RTLD_GLOBAL);

    chdir(NSBundle.mainBundle.bundlePath.UTF8String);
    NSDictionary *frameworks = [NSDictionary dictionaryWithContentsOfFile:@"../templates/generated.plist"];
    for(NSString *framework in frameworks) {
        NSString *outPath = [NSString stringWithFormat:@"../../GuestFrameworks/%@", framework];
        [NSFileManager.defaultManager createDirectoryAtPath:outPath withIntermediateDirectories:YES attributes:@{} error:nil];

        NSDictionary *classes = frameworks[framework];
        for(NSString *cls in classes) {
            ClassBuilder *classContent = [[ClassBuilder alloc] initWithClassDictionary:classes[cls]];
            [classContent.description writeToFile:[outPath stringByAppendingFormat:@"/%@.m", cls] atomically:YES];
        }
    }

    NSArray<Class> *classes = @[
        CABasicAnimation.class, CAKeyframeAnimation.class, CAPropertyAnimation.class, CAAnimation.class, CALayer.class, CAMediaTimingFunction.class, CATransaction.class,
        NSArray.class, NSMutableArray.class, NSAssertionHandler.class, NSAutoreleasePool.class, NSBundle.class, NSData.class, NSDate.class, NSDictionary.class, NSException.class, NSFileManager.class, NSLock.class, NSMutableArray.class, NSMutableArray.class, NSMutableDictionary.class, NSMutableString.class, NSNull.class, NSNumber.class, NSString.class, NSThread.class, NSTimer.class, NSURL.class, NSUserDefaults.class, NSValue.class,
        CLS(UIDynamicSystemColor), CLS(UIDynamicColor), CLS(UILayoutContainerView), CLS(UICachedDeviceWhiteColor), CLS(UIDeviceWhiteColor), UIAccelerometer.class, UIActivityIndicatorView.class, UIAlertView.class, UIApplication.class, UIBarButtonItem.class, UIBarItem.class, UIButton.class, UIColor.class, UIControl.class, UIFont.class, UIImage.class, UIImageView.class, UILabel.class, UINavigationBar.class, UINavigationController.class, UINavigationItem.class, UIPageControl.class, UIPickerView.class, UIResponder.class, UIScreen.class, UIScrollView.class, UITextField.class, UIToolbar.class, UIView.class, UIViewController.class, UIWindow.class
    ];
    for(Class cls in classes) {
        printf("Generating for %s\n", class_getName(cls));
        ClassBuilder *classContent = [[ClassBuilder alloc] initWithClass:cls];
        NSString *path = [NSString stringWithFormat:@"/var/mobile/Documents/TrollExperiments/CProjects/dynarmic/LiveExec32/GuestFrameworks/%@/%@.m", classContent.imagePath.lastPathComponent, NSStringFromClass(cls)];
        [NSFileManager.defaultManager createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:@{} error:nil];
        [classContent.description writeToFile:path atomically:YES];
    }

    return 0;
}
