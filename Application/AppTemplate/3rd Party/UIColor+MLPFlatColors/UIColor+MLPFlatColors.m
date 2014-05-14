/*
//  UIColor+MLPFlatColors.m
//  
//
//  Created by Eddy Borja on 4/10/13.
//  Copyright (c) 2013 Mainloop LLC. All rights reserved.
//
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */


#import "UIColor+MLPFlatColors.h"

@implementation UIColor (MLPFlatColors)

- (UIColor *)lighterColor {
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    }
    return nil;
}

- (UIColor *)darkerColor {
    CGFloat r, g, b, a;
    if ([self getRed:&r green:&g blue:&b alpha:&a]) {
        return [UIColor colorWithRed:MAX(r - 0.15, 0.0)
                               green:MAX(g - 0.15, 0.0)
                                blue:MAX(b - 0.15, 0.0)
                               alpha:a];
    }
    return nil;
}

- (NSString *)hexString
{
    NSArray *colorArray	= [self rgbaArray];
    int r = [colorArray[0] floatValue] * 255;
    int g = [colorArray[1] floatValue] * 255;
    int b = [colorArray[2] floatValue] * 255;
    NSString *red = [NSString stringWithFormat:@"%02x", r];
    NSString *green = [NSString stringWithFormat:@"%02x", g];
    NSString *blue = [NSString stringWithFormat:@"%02x", b];
	
    return [NSString stringWithFormat:@"#%@%@%@", red, green, blue];
}

- (NSArray *)rgbaArray
{
    // Takes a UIColor and returns R,G,B,A values in NSNumber form
    CGFloat r=0,g=0,b=0,a=0;
    
    if ([self respondsToSelector:@selector(getRed:green:blue:alpha:)]) {
        [self getRed:&r green:&g blue:&b alpha:&a];
    }
    else {
        const CGFloat *components = CGColorGetComponents(self.CGColor);
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    return @[[NSNumber numberWithFloat:r],[NSNumber numberWithFloat:g],[NSNumber numberWithFloat:b],[NSNumber numberWithFloat:a]];
}

+ (UIColor *)colorFromHexString:(NSString *)hexString
{
    unsigned rgbValue = 0;
    hexString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
	
    [scanner scanHexInt:&rgbValue];
	
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

#pragma mark - Red
+ (UIColor *)flatRedColor
{
    return UIColorFromRGB(0xE74C3C);
}
+ (UIColor *)flatDarkRedColor
{
    return UIColorFromRGB(0xC0392B);
}

#pragma mark - Green
+ (UIColor *)flatGreenColor
{
    return UIColorFromRGB(0x2ECC71);
}
+ (UIColor *)flatDarkGreenColor
{
    return UIColorFromRGB(0x27AE60);
}


#pragma mark - Blue
+ (UIColor *)flatBlueColor
{
    return UIColorFromRGB(0x3498DB);
}
+ (UIColor *)flatDarkBlueColor
{
    return UIColorFromRGB(0x2980B9);
}


#pragma mark - Teal
+ (UIColor *)flatTealColor
{
    return UIColorFromRGB(0x1ABC9C);
}
+ (UIColor *)flatDarkTealColor
{
    return UIColorFromRGB(0x16A085);
}

#pragma mark - Purple
+ (UIColor *)flatPurpleColor
{
    return UIColorFromRGB(0x9B59B6);
}
+ (UIColor *)flatDarkPurpleColor
{
    return UIColorFromRGB(0x8E44AD);
}


#pragma mark - Yellow
+ (UIColor *)flatYellowColor
{
    return UIColorFromRGB(0xF1C40F);
}
+ (UIColor *)flatDarkYellowColor
{
    return UIColorFromRGB(0xF39C12);
}


#pragma mark - Orange
+ (UIColor *)flatOrangeColor
{
    return UIColorFromRGB(0xE67E22);
}
+ (UIColor *)flatDarkOrangeColor
{
    return UIColorFromRGB(0xD35400);
}



#pragma mark - Gray
+ (UIColor *)flatGrayColor
{
    return UIColorFromRGB(0x95A5A6);
}

+ (UIColor *)flatDarkGrayColor
{
    return UIColorFromRGB(0x7F8C8D);
}



#pragma mark - White
+ (UIColor *)flatWhiteColor
{
    return UIColorFromRGB(0xECF0F1);
}

+ (UIColor *)flatDarkWhiteColor
{
    return UIColorFromRGB(0xBDC3C7);
}



#pragma mark - Black
+ (UIColor *)flatBlackColor
{
    return UIColorFromRGB(0x34495E);
}

+ (UIColor *)flatDarkBlackColor
{
    return UIColorFromRGB(0x2C3E50);
}



#pragma mark - Random
+ (UIColor *)randomFlatColor
{
    return [UIColor randomFlatColorIncludeLightShades:YES darkShades:YES];
}

+ (UIColor *)randomFlatLightColor
{
    return [UIColor randomFlatColorIncludeLightShades:YES darkShades:NO];
}

+ (UIColor *)randomFlatDarkColor
{
    return [UIColor randomFlatColorIncludeLightShades:NO darkShades:YES];
}

+ (UIColor *)randomFlatColorIncludeLightShades:(BOOL)useLightShades
                                    darkShades:(BOOL)useDarkShades;
{
    const NSInteger numberOfLightColors = 10;
    const NSInteger numberOfDarkColors = 10;
    NSAssert(useLightShades || useDarkShades, @"Must choose random color using at least light shades or dark shades.");

    
    u_int32_t numberOfColors = 0;
    if(useLightShades){
        numberOfColors += numberOfLightColors;
    }
    if(useDarkShades){
        numberOfColors += numberOfDarkColors;
    }

    u_int32_t chosenColor = arc4random_uniform(numberOfColors);
    
    if(!useLightShades){
        chosenColor += numberOfLightColors;
    }
    
    UIColor *color;
    switch (chosenColor) {
        case 0:
            color = [UIColor flatRedColor];
            break;
        case 1:
            color = [UIColor flatGreenColor];
            break;
        case 2:
            color = [UIColor flatBlueColor];
            break;
        case 3:
            color = [UIColor flatTealColor];
            break;
        case 4:
            color = [UIColor flatPurpleColor];
            break;
        case 5:
            color = [UIColor flatYellowColor];
            break;
        case 6:
            color = [UIColor flatOrangeColor];
            break;
        case 7:
            color = [UIColor flatGrayColor];
            break;
        case 8:
            color = [UIColor flatWhiteColor];
            break;
        case 9:
            color = [UIColor flatBlackColor];
            break;
        case 10:
            color = [UIColor flatDarkRedColor];
            break;
        case 11:
            color = [UIColor flatDarkGreenColor];
            break;
        case 12:
            color = [UIColor flatDarkBlueColor];
            break;
        case 13:
            color = [UIColor flatDarkTealColor];
            break;
        case 14:
            color = [UIColor flatDarkPurpleColor];
            break;
        case 15:
            color = [UIColor flatDarkYellowColor];
            break;
        case 16:
            color = [UIColor flatDarkOrangeColor];
            break;
        case 17:
            color = [UIColor flatDarkGrayColor];
            break;
        case 18:
            color = [UIColor flatDarkWhiteColor];
            break;
        case 19:
            color = [UIColor flatDarkBlackColor];
            break;
        case 20:
        default:
            NSAssert(0, @"Unrecognized color selected as random color");
            break;
    }
    
    return color;
}



@end
