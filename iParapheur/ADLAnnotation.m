//
//  ADLAnnotation.m
//  iParapheur
//
//  Created by Emmanuel Peralta on 09/10/12.
//
//

#import "ADLAnnotation.h"
#import "ADLRestClient.h"

@implementation ADLAnnotation

-(id) init {
    if ((self = [super init])) {
        _author = @"";
        _uuid = @"";
        _rect = CGRectZero;
        _text = @"";
        _editable = YES;
    }
    return self;
}

-(id) initWithAnnotationDict:(NSDictionary *)annotation {
	
    if (self = [super init]) {
		if ([[[ADLRestClient sharedManager] getRestApiVersion] intValue ] >= 3)
			_uuid = [annotation objectForKey:@"id"];
		else
			_uuid = [annotation objectForKey:@"uuid"];

        _author = [annotation objectForKey:@"author"];
        _rect = [self rectWithDict:[annotation objectForKey:@"rect"]];
        
        _editable = [(NSString *) [annotation objectForKey:@"editable"] boolValue];
        _text = [annotation objectForKey:@"text"];
    }
	
    return self;
}

/* compute the rect with pixels coordoniates */
-(CGRect)rectWithDict:(NSDictionary*)dict {
    NSDictionary *topLeft = [dict objectForKey:@"topLeft"];
    NSDictionary *bottomRight = [dict objectForKey:@"bottomRight"];
    
    NSNumber *x = [topLeft objectForKey:@"x"];
    NSNumber *y = [topLeft objectForKey:@"y"];
    
    NSNumber *x1 = [bottomRight objectForKey:@"x"];
    NSNumber *y1 = [bottomRight objectForKey:@"y"];
    
    CGRect arect = CGRectMake([x floatValue]  / 150.0f * 72.0f,
                      [y floatValue]  / 150.0f * 72.0f,
                      ([x1 floatValue]  / 150.0f * 72.0f) - ([x floatValue] / 150.0f * 72.0f), // width
                      ([y1 floatValue] / 150.0f * 72.0f) - ([y floatValue] / 150.0f * 72.0f)); // height
    
    return CGRectInset(arect, -14.0f, -14.0f);
}

-(NSDictionary*) dictWithRect:(CGRect) rect {
    CGRect realRect = CGRectInset(rect, 14.0f, 14.0f);
    
    NSMutableDictionary *rectDict = [[NSMutableDictionary alloc] init];
    
    NSMutableDictionary *topLeft = [[NSMutableDictionary alloc] init];
    [topLeft setObject:[NSNumber numberWithFloat:realRect.origin.x/72.0f * 150.0f] forKey:@"x"];
    [topLeft setObject:[NSNumber numberWithFloat:realRect.origin.y/72.0f * 150.0f] forKey:@"y"];
    
    NSMutableDictionary *bottomRight = [[NSMutableDictionary alloc] init];
    [bottomRight setObject:[NSNumber numberWithFloat:CGRectGetMaxX(realRect)/72.0f * 150.0f] forKey:@"x"];
    [bottomRight setObject:[NSNumber numberWithFloat:CGRectGetMaxY(realRect)/72.0f * 150.0f] forKey:@"y"];
    
    [rectDict setObject:topLeft forKey:@"topLeft"];
    [rectDict setObject:bottomRight forKey:@"bottomRight"];
    
    
    return rectDict;
}

-(NSDictionary*) dict {
    NSMutableDictionary *annotation = [[NSMutableDictionary alloc] init];
    
    if (_uuid != nil) {
        [annotation setObject:_uuid forKey:@"uuid"];
    }
    
    [annotation setObject:[self dictWithRect:_rect] forKey:@"rect"];
    [annotation setObject:_text forKey:@"text"];
    [annotation setObject:@"rect" forKey:@"type"];
    
    
    return annotation;
}

@end
