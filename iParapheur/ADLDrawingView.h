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
//  ADLDrawingView.h
//  testDrawing
//


#import <UIKit/UIKit.h>
#import "ADLAnnotationView.h"
#import "ReaderViewController.h"


#define MIN_WIDTH 50
#define MIN_HEIGHT 50


@protocol ADLDrawingViewDataSource <NSObject>

- (NSArray *)annotationsForPage:(NSInteger)page;

- (void)updateAnnotation:(ADLAnnotation *)annotation
                 forPage:(NSUInteger)page;

- (void)removeAnnotation:(ADLAnnotation *)annotation;

- (void)addAnnotation:(ADLAnnotation *)annotation
              forPage:(NSUInteger)page;

@optional

@end


@class ADLAnnotationView;


@interface ADLDrawingView : UIView

@property(nonatomic, strong) ADLAnnotationView *hittedView;
@property(nonatomic, strong) UIView *currentAnnotView;
@property(nonatomic) CGPoint origin;
@property(nonatomic) CGFloat dx;
@property(nonatomic) CGFloat dy;

@property(nonatomic) BOOL enabled;
@property(nonatomic) BOOL shallUpdateCurrent;

@property(nonatomic) BOOL hasBeenLongPressed;

@property(nonatomic, weak) UIScrollView *parentScrollView;
@property(nonatomic, weak) UIScrollView *superScrollView;
@property(nonatomic, weak) ReaderViewController *masterViewController;

@property(nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;

@property(nonatomic) NSUInteger pageNumber;

@property(nonatomic) UIEdgeInsets contentInset;
@property(nonatomic) CGPoint contentOffset;

@property(nonatomic) CGRect keyboardRect;
@property(nonatomic) BOOL keyboardVisible;


- (id)initWithFrame:(CGRect)frame;

- (void)refreshAnnotations;

- (CGSize)getPageSize;

- (CGRect)clipRectInView:(CGRect)rect;

- (void)updateAnnotation:(ADLAnnotation *)annotation;

- (void)addAnnotation:(ADLAnnotation *)annotation;

- (void)removeAnnotation:(ADLAnnotation *)annotation;

- (NSArray *)annotationsForPage:(NSUInteger)page;

- (void)handleDoubleTap:(UIGestureRecognizer *)gestureRecognizer;


@end


