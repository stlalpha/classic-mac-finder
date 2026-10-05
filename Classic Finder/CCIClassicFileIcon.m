//
//  CCIClassicFileIcon.m
//  Classic Finder
//
//  Created by Ben Szymanski on 10/4/17.
//  Copyright © 2017 Ben Szymanski. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "CCIClassicFileIcon.h"
#import "CCIApplicationStyles.h"
#import <math.h>

static NSBitmapImageRep *CCIIconBitmap(NSUInteger width, NSUInteger height)
{
    return [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                    pixelsWide:(NSInteger)width
                                                    pixelsHigh:(NSInteger)height
                                                 bitsPerSample:8
                                               samplesPerPixel:4
                                                      hasAlpha:YES
                                                      isPlanar:NO
                                                colorSpaceName:NSDeviceRGBColorSpace
                                                   bitmapFormat:NSBitmapFormatAlphaFirst
                                                    bytesPerRow:0
                                                   bitsPerPixel:0];
}

static NSImage *CCIRenderMacOS9Icon(NSImage *source)
{
    const NSUInteger classicSize = 32;
    NSBitmapImageRep *smallBitmap = CCIIconBitmap(classicSize, classicSize);
    if (smallBitmap == nil) return source;

    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:smallBitmap];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    context.imageInterpolation = NSImageInterpolationHigh;
    [source drawInRect:NSMakeRect(0, 0, classicSize, classicSize)
              fromRect:NSZeroRect
             operation:NSCompositingOperationSourceOver
              fraction:1.0];
    [context flushGraphics];
    [NSGraphicsContext restoreGraphicsState];

    // Classic Finder icons were authored for a small pixel grid. Reduce modern
    // app artwork to that grid, soften vector gradients into a compact palette,
    // then scale it back with nearest-neighbor sampling for crisp Retina edges.
    NSBitmapImageRep *retinaBitmap = CCIIconBitmap(classicSize * 2, classicSize * 2);
    if (retinaBitmap == nil) return [[NSImage alloc] initWithCGImage:smallBitmap.CGImage size:NSMakeSize(classicSize, classicSize)];
    retinaBitmap.size = NSMakeSize(classicSize, classicSize);

    for (NSUInteger y = 0; y < classicSize; y++) {
        for (NSUInteger x = 0; x < classicSize; x++) {
            NSColor *color = [[smallBitmap colorAtX:(NSInteger)x y:(NSInteger)y] colorUsingColorSpace:[NSColorSpace deviceRGBColorSpace]];
            CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
            if (alpha > 0.0) {
                const CGFloat paletteSteps = 7.0;
                red = round(red * paletteSteps) / paletteSteps;
                green = round(green * paletteSteps) / paletteSteps;
                blue = round(blue * paletteSteps) / paletteSteps;
            }
            NSColor *pixel = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
            [retinaBitmap setColor:pixel atX:(NSInteger)(x * 2) y:(NSInteger)(y * 2)];
            [retinaBitmap setColor:pixel atX:(NSInteger)(x * 2 + 1) y:(NSInteger)(y * 2)];
            [retinaBitmap setColor:pixel atX:(NSInteger)(x * 2) y:(NSInteger)(y * 2 + 1)];
            [retinaBitmap setColor:pixel atX:(NSInteger)(x * 2 + 1) y:(NSInteger)(y * 2 + 1)];
        }
    }

    NSImage *styledImage = [[NSImage alloc] initWithSize:NSMakeSize(classicSize, classicSize)];
    [styledImage addRepresentation:retinaBitmap];
    return styledImage;
}

@interface CCIClassicFileIcon()

@property BOOL selectedState;

@end

@implementation CCIClassicFileIcon

+ (NSImage *)macOS9StyledApplicationIconForURL:(NSURL *)url
{
    return [self macOS9StyledIconForURL:url];
}

+ (NSImage *)macOS9StyledIconForURL:(NSURL *)url
{
    if (url == nil || !url.isFileURL) return nil;
    static NSCache<NSString *, NSImage *> *iconCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ iconCache = [[NSCache alloc] init]; });

    NSString *cacheKey = url.standardizedURL.path;
    NSImage *cachedImage = [iconCache objectForKey:cacheKey];
    if (cachedImage != nil) return cachedImage;

    NSImage *systemIcon = [[NSWorkspace sharedWorkspace] iconForFile:cacheKey];
    NSImage *styledImage = CCIRenderMacOS9Icon(systemIcon);
    if (styledImage != nil) [iconCache setObject:styledImage forKey:cacheKey];
    return styledImage;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    
    if (self) {
        self.selectedState = NO;
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    if ([CCIApplicationStyles instance].appearanceVersion == CCIClassicAppearanceMacOS9) {
        NSImage *fileImage = self.applicationImage ?: [NSImage imageNamed:@"MacOS9Document"];
        if (fileImage != nil) {
            [fileImage drawInRect:self.bounds fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1.0 respectFlipped:self.isFlipped hints:nil];
            if (self.selectedState) {
                [NSGraphicsContext saveGraphicsState];
                [NSBezierPath clipRect:self.bounds];
                [[NSColor.blackColor colorWithAlphaComponent:0.28] setFill];
                NSRectFillUsingOperation(self.bounds, NSCompositingOperationSourceAtop);
                [NSGraphicsContext restoreGraphicsState];
            }
            return;
        }
    }
    
    if (self.selectedState)
    {
        [[[CCIApplicationStyles instance] whiteColor] setStroke];
        [[[CCIApplicationStyles instance] blackColor] setFill];
        
        NSBezierPath *fileShape = [[NSBezierPath alloc] init];
        [fileShape moveToPoint:NSMakePoint(18.0, 0.5)];
        [fileShape lineToPoint:NSMakePoint(0.5, 0.5)];
        [fileShape lineToPoint:NSMakePoint(0.5, 29.5)];
        [fileShape lineToPoint:NSMakePoint(22.5, 29.5)];
        [fileShape lineToPoint:NSMakePoint(22.5, 5.5)];
        [fileShape lineToPoint:NSMakePoint(18.0, 0.5)];
        
        [fileShape fill];
        
        NSBezierPath *pageFlapOutline = [[NSBezierPath alloc] init];
        [pageFlapOutline moveToPoint:NSMakePoint(18.0, 0.5)];
        [pageFlapOutline lineToPoint:NSMakePoint(18.0, 6.0)];
        [pageFlapOutline lineToPoint:NSMakePoint(23.0, 6.0)];
        
        [pageFlapOutline stroke];
    } else
    {
        [[[CCIApplicationStyles instance] blackColor] setStroke];
        [[[CCIApplicationStyles instance] whiteColor] setFill];
        
        NSBezierPath *outlinePath = [[NSBezierPath alloc] init];
        [outlinePath moveToPoint:NSMakePoint(18.0, 0.5)];
        [outlinePath lineToPoint:NSMakePoint(0.5, 0.5)];
        [outlinePath lineToPoint:NSMakePoint(0.5, 29.5)];
        [outlinePath lineToPoint:NSMakePoint(22.5, 29.5)];
        [outlinePath lineToPoint:NSMakePoint(22.5, 5.5)];
        [outlinePath lineToPoint:NSMakePoint(18.0, 0.5)];
        [outlinePath lineToPoint:NSMakePoint(18.0, 6.0)];
        [outlinePath lineToPoint:NSMakePoint(23.0, 6.0)];
        
        [outlinePath fill];
        [outlinePath stroke];
    }
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)selectFile
{
    self.selectedState = YES;
    [self setNeedsDisplay:YES];
}

- (void)deselectFile
{
    self.selectedState = NO;
    [self setNeedsDisplay:YES];
}

@end
