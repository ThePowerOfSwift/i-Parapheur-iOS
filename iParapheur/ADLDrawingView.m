/*
 * Version 1.1
 * CeCILL Copyright (c) 2012, SKROBS, ADULLACT-projet
 * Initiated by ADULLACT-projet S.A.
 * Developped by SKROBS
 *
 * contact@adullact-projet.coop
 *
 * Ce logiciel est un programme informatique servant à faire circuler des
 * documents au travers d'un circuit de validation, où chaque acteur vise
 * le dossier, jusqu'à l'étape finale de signature.
 *
 * Ce logiciel est régi par la licence CeCILL soumise au droit français et
 * respectant les principes de diffusion des logiciels libres. Vous pouvez
 * utiliser, modifier et/ou redistribuer ce programme sous les conditions
 * de la licence CeCILL telle que diffusée par le CEA, le CNRS et l'INRIA
 * sur le site "http://www.cecill.info".
 *
 * En contrepartie de l'accessibilité au code source et des droits de copie,
 * de modification et de redistribution accordés par cette licence, il n'est
 * offert aux utilisateurs qu'une garantie limitée.  Pour les mêmes raisons,
 * seule une responsabilité restreinte pèse sur l'auteur du programme,  le
 * titulaire des droits patrimoniaux et les concédants successifs.
 *
 * A cet égard  l'attention de l'utilisateur est attirée sur les risques
 * associés au chargement,  à l'utilisation,  à la modification et/ou au
 * développement et à la reproduction du logiciel par l'utilisateur étant
 * donné sa spécificité de logiciel libre, qui peut le rendre complexe à
 * manipuler et qui le réserve donc à des développeurs et des professionnels
 * avertis possédant  des  connaissances  informatiques approfondies.  Les
 * utilisateurs sont donc invités à charger  et  tester  l'adéquation  du
 * logiciel à leurs besoins dans des conditions permettant d'assurer la
 * sécurité de leurs systèmes et ou de leurs données et, plus généralement,
 * à l'utiliser et l'exploiter dans les mêmes conditions de sécurité.
 *
 * Le fait que vous puissiez accéder à cet en-tête signifie que vous avez
 * pris connaissance de la licence CeCILL, et que vous en avez accepté les
 * termes.
 */

//
//  ADLDrawingView.m
//  testDrawing
//

#import "ADLDrawingView.h"
#import <QuartzCore/QuartzCore.h>

#define _UIKeyboardFrameEndUserInfoKey (&UIKeyboardFrameEndUserInfoKey != NULL ? UIKeyboardFrameEndUserInfoKey : @"UIKeyboardBoundsUserInfoKey")


@implementation ADLDrawingView

- (id)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _hittedView = nil;
        _currentAnnotView = nil;
		
		// DoubleTabGestureRecogniser
		
        UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
																									 action:@selector(handleDoubleTap:)];
        doubleTapGestureRecognizer.numberOfTapsRequired = 2;
		
        [self addGestureRecognizer:doubleTapGestureRecognizer];

		// LongPressGestureRecogniser
		
        _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
																					action:@selector(handleLongPress:)];
        
        _longPressGestureRecognizer.cancelsTouchesInView = NO;
        
        [self addGestureRecognizer:_longPressGestureRecognizer];
		
        // by default disable annotations
		
        _enabled = YES;
        _shallUpdateCurrent = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillShow:)
													 name:UIKeyboardWillShowNotification
												   object:nil];
		
        [[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(keyboardWillHide:)
													 name:UIKeyboardWillHideNotification
												   object:nil];
    }
    return self;
}


- (void)awakeFromNib {
    _hittedView = nil;
    _currentAnnotView = nil;
}


-(CGFloat)idealOffsetForView:(UIView *)view
				   withSpace:(CGFloat)space {
    
    // Convert the rect to get the view's distance from the top of the scrollView.
    CGRect rect = [view convertRect:view.bounds toView:[self superScrollView]];
    
    // Set starting offset to that point
    CGFloat offset = rect.origin.y - (space / 2.0f) + (rect.size.height / 2.0f);
    
        
    /*
    if ( self.superScrollView.contentSize.height - offset < space ) {
        // Scroll to the bottom
        offset = self.superScrollView.contentSize.height - space;
    } else {
        if ( view.bounds.size.height < space ) {
            // Center vertically if there's room
            offset -= floor((space-view.bounds.size.height)/2.0);
        }
        if ( offset + space > self.superScrollView.contentSize.height ) {
            // Clamp to content size
            offset = self.superScrollView.contentSize.height - space;
        }
    }*/
    
    if (offset < 0) offset = 0;
    
    return offset;
}


- (UIView*)findFirstResponderBeneathView:(UIView*)view {
    // Search recursively for first responder
    for ( UIView *childView in view.subviews ) {
        if ( [childView respondsToSelector:@selector(isFirstResponder)] && [childView isFirstResponder] ) return childView;
        UIView *result = [self findFirstResponderBeneathView:childView];
        if ( result ) return result;
    }
    return nil;
}


-(void)keyboardWillShow:(NSNotification*)notification {
    _keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    _keyboardVisible = YES;
    
    UIView *firstResponder = [self findFirstResponderBeneathView:self];
    if ( !firstResponder ) {
        // No child view is the first responder - nothing to do here
        return;
    }
    
    /*
    if (!_priorInsetSaved) {
        _priorInset = self.contentInset;
        _priorInsetSaved = YES;
    }*/
    
    // Shrink view's inset by the keyboard's height, and scroll to show the text field/view being edited
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
    
    self.contentInset = [self contentInsetForKeyboard];
    [[self superScrollView] setContentOffset:CGPointMake(self.superScrollView.contentOffset.x,
                                       [self idealOffsetForView:firstResponder withSpace:[self keyboardRect].size.width])
                  animated:YES];
    [[self parentScrollView] setScrollIndicatorInsets:_contentInset];
    
    [UIView commitAnimations];
}


-(void)keyboardWillHide:(NSNotification*)notification {
    _keyboardRect = CGRectZero;
    _keyboardVisible = NO;
    
    // Restore dimensions to prior size
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:[[[notification userInfo] objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    [UIView setAnimationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue]];
  //_contentInset = _priorInset;
    _contentOffset = CGPointZero;
    [[self parentScrollView] setScrollIndicatorInsets:_contentInset];
    //_priorInsetSaved = NO;
    [UIView commitAnimations];
}


-(UIEdgeInsets)contentInsetForKeyboard {
    UIEdgeInsets newInset = _contentInset;
    CGRect keyboardRect = [self keyboardRect];
    newInset.bottom = keyboardRect.size.height - ((keyboardRect.origin.y+keyboardRect.size.height) - (self.bounds.origin.y+self.bounds.size.height));
    return newInset;
}


-(void)handleSingleTap:(UIGestureRecognizer *)gestureRecognizer {
    // CGPoint touchPoint = [gestureRecognizer locationInView:self];
    //    UIView *hitted = [self hitTest:touchPoint withEvent:event];
}


-(void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer {
	
    if (!_hittedView && _enabled) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self];
        CGRect annotFrame = [self clipRectInView:CGRectMake(touchPoint.x, touchPoint.y, kAnnotationMinHeight, kAnnotationMinWidth)];
        _currentAnnotView = [[ADLAnnotationView alloc] initWithFrame:annotFrame];
        [_currentAnnotView setContentScaleFactor:[_parentScrollView contentScaleFactor]];
        
        [(ADLAnnotationView*)_currentAnnotView refreshModel];
        
        [self addAnnotation:[(ADLAnnotationView*)_currentAnnotView annotationModel]];
        
        [self addSubview:_currentAnnotView];
    }
}


-(void)setContentScaleFactor:(CGFloat)contentScaleFactor {
    //[super setContentScaleFactor:contentScaleFactor];
    for (UIView *subview in self.subviews) {
        [subview setContentScaleFactor:contentScaleFactor];
    }
}


-(void)handleLongPress:(UIGestureRecognizer *)gestureRecognizer {
    CGPoint touchPoint = [gestureRecognizer locationInView:self];
    
    if (_hittedView && _enabled && _hittedView.annotationModel.editable) {
        [self animateviewOnLongPressGesture:touchPoint];
        _hasBeenLongPressed = YES;
    }
}


-(void)touchesBegan:(NSSet *)touches
		  withEvent:(UIEvent *)event {
	
	[super touchesBegan:touches
			  withEvent:event];
    
    if (_enabled) {
        UITouch *touch = [[event allTouches] anyObject];
        
        CGPoint touchPoint = [self clipPointToView:[touch locationInView:self]];
        
        UIView *hitted = [self hitTest:touchPoint withEvent:event];
        
        if ([hitted isKindOfClass:[ADLAnnotationView class]] || [hitted isKindOfClass:[ADLDrawingView class]]) {

            [self unselectAnnotations];
            _hittedView = nil;
            
            
            if (hitted != self) {
                
                [(ADLAnnotationView*)hitted handleTouchInside];
                //if (_hasBeenLongPressed) {
                _parentScrollView.scrollEnabled = NO;
                _superScrollView.scrollEnabled = NO;
                _hittedView = (ADLAnnotationView*)hitted;
                _origin = hitted.frame.origin;
                _dx = sqrt(pow(_origin.x - touchPoint.x, 2.0));
                _dy = sqrt(pow(_origin.y - touchPoint.y, 2.0));
                _currentAnnotView = nil;
                
                if ([_hittedView isInHandle:[touch locationInView:self]]) {
                    _longPressGestureRecognizer.enabled = NO;
                }
                
                [_hittedView setSelected:true];
                [_hittedView setNeedsDisplay];
            }
            else {
                _parentScrollView.scrollEnabled = YES;
                _superScrollView.scrollEnabled = YES;
                _hasBeenLongPressed = NO;
                
            }
        }
    }
}


-(void)unselectAnnotations {
    for (UIView* subview in [self subviews]) {
        if ([subview class] == [ADLAnnotationView class]) {
            ADLAnnotationView *a = (ADLAnnotationView*)subview;
            [a setSelected:NO];
        }
    }
}


-(void)displayAnnotations:(NSArray*)annotations {
    ADLAnnotationView *annotView = nil;
    for (NSDictionary* dict in annotations) {
        CGRect annotRect;
        annotView = [[ADLAnnotationView alloc] initWithFrame:annotRect];
        [self addSubview:annotView];
    }
}


-(CGRect)convertFromPixelRect:(CGRect)pixelRect {
    return CGRectZero;
}


-(CGRect)convertToPixelRect:(CGRect)uiViewRect {
    return CGRectZero;
}


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (_enabled) {
        UITouch *touch = [touches anyObject];
        
        if ([_hittedView isKindOfClass:[ADLAnnotationView class]] || [_hittedView isKindOfClass:[ADLDrawingView class]]) {
            CGPoint point = [self clipPointToView:[touch locationInView:self]];
            if (_hittedView.annotationModel.editable) {
                if ([_hittedView isInHandle:[touch locationInView:self]]) {
                    
                    CGRect frame = [_hittedView frame];
                    
                    frame.size.width = point.x - frame.origin.x;
                    frame.size.height = point.y - frame.origin.y;
                    _parentScrollView.scrollEnabled = NO;
                    _superScrollView.scrollEnabled = NO;
                    _shallUpdateCurrent = YES;
                    
                    [_hittedView setFrame:frame];
                    [_hittedView setNeedsDisplay];
                }
                else if (_hittedView && _hasBeenLongPressed) {
                    CGRect frame = [_hittedView frame];
                    
                    frame.origin.x = point.x - _dx;
                    frame.origin.y = point.y - _dy;
                    
                    frame = [self clipRectInView:frame];
                    
                    _parentScrollView.scrollEnabled = NO;
                    _superScrollView.scrollEnabled = NO;
                    _shallUpdateCurrent = YES;
                    [_hittedView setFrame:frame];
                }
            }
			
            [self touchesCancelled:touches
						 withEvent:event];
        }
    }
    
}


-(void)touchesEnded:(NSSet *)touches
		  withEvent:(UIEvent *)event {
	
	if (_enabled) {
		
        UITouch *touch = [touches anyObject];
        
        if (_hasBeenLongPressed) {
            _hasBeenLongPressed = NO;
            [self unanimateView:[touch locationInView:self]];
        }
        
        if (_hittedView != nil && [_hittedView isKindOfClass:[ADLAnnotationView class]] && _shallUpdateCurrent) {

			[_hittedView refreshModel];
            ADLAnnotation *annotation = [_hittedView annotationModel];
            
            if (self.hittedView.annotationModel.uuid && self.hittedView.annotationModel.editable)
                [self updateAnnotation:annotation];
        }
        
        //_hittedView = nil;
        _parentScrollView.scrollEnabled = YES;
        _superScrollView.scrollEnabled = YES;
        _longPressGestureRecognizer.enabled = YES;
        
        _shallUpdateCurrent = NO;
    }
    
}


-(CGPoint)clipPointToView:(CGPoint)touch {
    
    CGPoint ret = touch;
    
    if (touch.x < 0) {
        ret.x = 0;
    }
    
    if (touch.x > self.frame.size.width) {
        ret.x = self.frame.size.width;
    }
    
    if (touch.y < 0) {
        ret.y = 0;
    }
    
    if (touch.y > self.frame.size.height) {
        ret.y = self.frame.size.height;
    }
    
    return ret;
    
    
}


-(CGRect)clipRectInView:(CGRect)rect {
    CGRect frame = [self frame];
    CGRect clippedRect = rect;
    
    CGFloat dx= 0.0f;
    CGFloat dy= 0.0f;
    
    if (CGRectGetMaxX(rect) > CGRectGetMaxX(frame)) {
        // overflow
        dx = CGRectGetMaxX(rect) - CGRectGetMaxX(frame);
    }
    
    
    if (CGRectGetMaxY(rect) > CGRectGetMaxY(frame)) {
        dy = CGRectGetMaxY(rect) - CGRectGetMaxY(frame);
    }
    
    clippedRect.origin.x -= dx;
    clippedRect.origin.y -= dy;
    
    clippedRect.origin = [self clipPointToView:clippedRect.origin];
    return clippedRect;
}


-(void)animateviewOnLongPressGesture:(CGPoint)touchPoint {
#define GROW_ANIMATION_DURATION_SECONDS 0.15
	
	NSValue *touchPointValue = [NSValue valueWithCGPoint:touchPoint];
	[UIView beginAnimations:nil context:(__bridge void *)(touchPointValue)];
	[UIView setAnimationDuration:GROW_ANIMATION_DURATION_SECONDS];
	[UIView setAnimationDelegate:self];
	//[UIView setAnimationDidStopSelector:@selector(growAnimationDidStop:finished:context:)];
	CGAffineTransform transform = CGAffineTransformMakeScale(1.1f, 1.1f);
	_hittedView.transform = transform;
	[UIView commitAnimations];
    
}


-(void)unanimateView:(CGPoint) touchPoint {
#define MOVE_ANIMATION_DURATION_SECONDS 0.15
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:MOVE_ANIMATION_DURATION_SECONDS];
	_hittedView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
	/*
	 Move the placardView to under the touch.
	 We passed the location wrapped in an NSValue as the context.
	 Get the point from the value, then release the value because we retained it in touchesBegan:withEvent:.
	 */
	//_hittedView.center = touchPoint;
	[UIView commitAnimations];
}


#pragma mark - dataSource


-(void)refreshAnnotations {
    
    for (UIView *a in [self subviews]) {
        [a removeFromSuperview];
    }
	    
    if (_dataSource != nil) {
        NSArray *annotations = [self annotationsForPage:_pageNumber];
        
        for (NSDictionary *annotation in annotations) {
			
            ADLAnnotation *annotModel = [[ADLAnnotation alloc] initWithAnnotationDict:annotation];
            
          //  CGRect annotRect = [annotModel rect];
             
            ADLAnnotationView *a = [[ADLAnnotationView alloc] initWithAnnotation:annotModel];
            [a setDrawingView:self];
            [self addSubview:a];
            

        }
    }
    
}


-(void)updateAnnotation:(ADLAnnotation*)annotation {
	
    [_dataSource updateAnnotation:annotation
						  forPage:_pageNumber];
}


-(void)addAnnotation:(ADLAnnotation*)annotation {
	
    [_dataSource addAnnotation:annotation
					   forPage:_pageNumber];
}


-(void)removeAnnotation:(ADLAnnotation*) annotation {
    [_dataSource removeAnnotation:annotation];
}


-(NSArray*)annotationsForPage:(NSUInteger)page {
    if (_enabled) {
        if ([_dataSource respondsToSelector:@selector(annotationsForPage:)]) {
            return [_dataSource annotationsForPage:page];
        }
    }
    return nil;
}


#pragma mark - Abstract Method


-(CGSize)getPageSize {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}


@end
