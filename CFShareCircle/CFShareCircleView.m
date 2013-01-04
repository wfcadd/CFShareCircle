//
//  CFShareCircleView.m
//  CFShareCircle
//
//  Created by Camden on 12/18/12.
//  Copyright (c) 2012 Camden. All rights reserved.
//

#import "CFShareCircleView.h"

@implementation CFShareCircleView

@synthesize delegate;

-(id)init{
    self = [super init];
    if (self) {
        [self initialize];
        [self setImages:[[NSArray alloc] initWithObjects:@"evernote.png", @"facebook.png", @"twitter.png", @"message.png", @"email.png", nil]];
    }
    return self;
}

- (id)initWithImageFileNames: (NSArray*)imageFileNames{
    self = [super init];
    if (self) {
        [self initialize];
        [self setImages:imageFileNames];
    }
    return self;
}

/* Set all the default values for the share circle. */
- (void)initialize{
    // Initialization code
    _largeRectSize = 250;
    _smallRectSize = 50;
    _pathRectSize = 180;
    _tempRectSize = 50;
    
    self.hidden = YES;
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    
    closeButtonImage = [UIImage imageNamed:@"close_button.png"];
    touchImage = [UIImage imageNamed:@"touch.png"];
    
    [self setFrame:CGRectMake(320, 0, 320, 480)];
    [self setBounds:CGRectMake(0, 0, 320, 480)];
    
    self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    if(_origin.y != rect.size.height/2){
        _origin = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
        _currentPosition = _origin;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Draw the larger circle.
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGRect largeCircleRect = CGRectMake(_origin.x - _largeRectSize/2,_origin.y - _largeRectSize/2,_largeRectSize,_largeRectSize);
    CGContextAddEllipseInRect(context, largeCircleRect);
    CGContextFillPath(context);
    
    [self drawCloseButtonWithContext:context];
    [self drawImagesWithContext:context];
    [self drawTouchRegionWithContext:context];
}

/**
 TOUCH METHODS
 **/

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = (UITouch *)[[touches allObjects] objectAtIndex:0];
    
    CGPoint point = [touch locationInView:self];
    
    // Make sure the user starts with touch inside the circle.
    if([self closeButtonEnclosesPoint: point]){
        _currentPosition = _origin;
        [self.delegate shareCircleViewWasCanceled];
    }
    else if([self circleEnclosesPoint: point]){
        _currentPosition = [self translatePoint:[touch locationInView:self]];
        _dragging = YES;
    }
    
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    if(_dragging){
        UITouch *touch = (UITouch *)[[touches allObjects] objectAtIndex:0];
        _currentPosition = [self translatePoint:[touch locationInView:self]];
        [self setNeedsDisplay];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    if(_dragging){
        // Determine if the location it ended in was in one of the rectangles.
        UITouch *touch = (UITouch *)[[touches allObjects] objectAtIndex:0];
        _currentPosition = [self translatePoint:[touch locationInView:self]];
        
        // Loop through all the rects to see if the user selected one.
        for(int i = 0; i < [images count]; i++){
            CGPoint point = [self pointAtIndex:i];
            
            // Determine if point is inside rect.
            if(CGRectContainsPoint(CGRectMake(point.x, point.y, _tempRectSize, _tempRectSize), _currentPosition))
                [self.delegate shareCircleView:self didSelectIndex:i];
        }
        
        _currentPosition = _origin;
        _dragging = NO;
        [self setNeedsDisplay];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    // Reset location.
    _currentPosition = _origin;
    _dragging = NO;
    [self setNeedsDisplay];
}

/**
 DRAWING METHODS
 **/

/* Draws all the images from the list. */
- (void) drawImagesWithContext:(CGContextRef) context{
    
    for (int i = 0; i < [images count]; i++) {
        UIImage *image = [images objectAtIndex:i];
        
        // Create the rect and the point to draw the image.
        CGPoint point = [self pointAtIndex:i];
        CGRect rect = CGRectMake(point.x,point.y, _tempRectSize,_tempRectSize);
        
        // Start image context.
        UIGraphicsBeginImageContext(image.size);
        UIGraphicsPushContext(context);
        
        // Draw the image.
        if(CGRectContainsPoint(CGRectMake(point.x, point.y, _tempRectSize, _tempRectSize), _currentPosition))
            [image drawInRect:rect];
        else
            [image drawInRect:rect blendMode:kCGBlendModeNormal alpha:0.8];
        
        // End image context.
        UIGraphicsPopContext();
        UIGraphicsEndImageContext();
    }
}

/* Draw the close button. */
- (void) drawCloseButtonWithContext:(CGContextRef) context{
    
    // Create the rect and the point to draw the image.
    // Calculate the x and y coordinate at pi/4.
    float x = _origin.x - closeButtonImage.size.width/2.0 + cosf(M_PI/4)*_largeRectSize/2.0;
    float y = _origin.y - closeButtonImage.size.height/2.0 - sinf(M_PI/4)*_largeRectSize/2.0;
    
    CGRect tempRect = CGRectMake(x,y,closeButtonImage.size.width,closeButtonImage.size.height);
    
    // Start image context.
    UIGraphicsBeginImageContext(closeButtonImage.size);
    UIGraphicsPushContext(context);
    
    // Draw the image.
    [closeButtonImage drawInRect:tempRect];
    
    // End image context.
    UIGraphicsPopContext();
    UIGraphicsEndImageContext();
}

/* Draw touch region. */
- (void) drawTouchRegionWithContext: (CGContextRef) context{
    // Create the rect and the point to draw the image.
    CGRect smallCircleRect = CGRectMake(_currentPosition.x - touchImage.size.width/2.0,_currentPosition.y - touchImage.size.height/2.0,touchImage.size.width,touchImage.size.height);
    
    // Start image context.
    UIGraphicsBeginImageContext(touchImage.size);
    UIGraphicsPushContext(context);
    
    // Determine alpha based on if the user is dragging.
    float alpha;
    if(_dragging)
        alpha = 1.0;
    else
        alpha = 0.3;
    
    // Draw the image.
    [touchImage drawInRect:smallCircleRect blendMode:kCGBlendModeNormal alpha:alpha];
    
    // End image context.
    UIGraphicsPopContext();
    UIGraphicsEndImageContext();
}

/**
 ANIMATION METHODS
 **/
- (void) animateIn{
    self.hidden = NO;
    
    [UIView animateWithDuration: 0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         [self setFrame:CGRectMake(0, 0, 320, 480)];
                     }
                     completion:^(BOOL finished){}];
}

- (void) animateOut{   
    [UIView animateWithDuration: 0.2
                          delay: 0.0
                        options: UIViewAnimationOptionCurveEaseOut
                     animations:^{
                         [self setFrame:CGRectMake(320, 0, 320, 480)];
                     }
                     completion:^(BOOL finished){
                         self.hidden = YES;
                     }];
}

/**
 HELPER METHODS
 **/

/* Method makes sure that the generated point won't be outside of the larger circle. */
- (CGPoint) translatePoint:(CGPoint)point{
    
    float touchImageSize = touchImage.size.height;
    
    if(pow(_largeRectSize/2.0 - touchImageSize/2.0,2) < (pow(point.x - _origin.x,2) + pow(point.y - _origin.y,2))){
        // Translate the x point.
        if(point.x > _origin.x + _largeRectSize/2.0 - touchImageSize/2.0)
            point.x = _origin.x + _largeRectSize/2.0 - touchImageSize/2.0;
        else if(point.x < _origin.x - _largeRectSize/2.0 + touchImageSize/2.0)
            point.x = _origin.x - _largeRectSize/2.0 + touchImageSize/2.0;
        
        // Translate the y point.
        if(point.y > _origin.y)
            point.y = sqrt(pow(_largeRectSize/2.0 - touchImageSize/2.0,2) - pow(point.x - _origin.x,2)) + _origin.y;
        else
            point.y = -sqrt(pow(_largeRectSize/2.0 - touchImageSize/2.0,2) - pow(point.x - _origin.x,2)) + _origin.y;
    }
    
    return point;
}

/* Get the point at the specified index. */
- (CGPoint) pointAtIndex:(int) index{
    // Number for trig.
    float trig = index/([images count]/2.0)*M_PI;
    
    // Calculate the x and y coordinate.
    // Points go around the unit circle starting at pi = 0.
    float x = _origin.x - _tempRectSize/2.0 + cosf(trig)*_pathRectSize/2.0;
    float y = _origin.y - _tempRectSize/2.0 - sinf(trig)*_pathRectSize/2.0;
    
    return CGPointMake(x, y);
}

/* Helper method to determine if a specified point is inside the circle. */
- (BOOL) circleEnclosesPoint: (CGPoint) point{
    if(pow(_largeRectSize/2.0,2) < (pow(point.x - _origin.x,2) + pow(point.y - _origin.y,2)))
        return NO;
    else
        return YES;
}

/* Helper method to determine if a specified point is inside the close button. */
- (BOOL) closeButtonEnclosesPoint: (CGPoint) point{
    float x = _origin.x - closeButtonImage.size.width/2.0 + cosf(M_PI/4)*_largeRectSize/2.0;
    float y = _origin.y - closeButtonImage.size.height/2.0 - sinf(M_PI/4)*_largeRectSize/2.0;
    
    CGRect tempRect = CGRectMake(x,y,closeButtonImage.size.width,closeButtonImage.size.height);
    
    if(CGRectContainsPoint(tempRect, point))
        return YES;
    else
        return NO;
}

/* Override setter method for imageFileNames so that when they are set the images can be preloaded.
 * This is important so that the images aren't loaded everytime drawRect is called.
 */
- (void) setImages:(NSArray *)imageFileNames{
    images = [[NSMutableArray alloc] init];
    // Preload all the images.
    for (int i = 0; i < [imageFileNames count]; i++) {
        [images addObject:[UIImage imageNamed:[imageFileNames objectAtIndex:i]]];
    }
}

@end
