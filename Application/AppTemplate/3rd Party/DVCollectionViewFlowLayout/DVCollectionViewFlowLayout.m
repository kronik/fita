#import "DVCollectionViewFlowLayout.h"

@interface DVCollectionViewFlowLayout()

@property (nonatomic, strong) UIDynamicAnimator *dynamicAnimator;

@end

@implementation DVCollectionViewFlowLayout

@synthesize dynamicAnimator = _dynamicAnimator;

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self){
        _dynamicAnimator = [[UIDynamicAnimator alloc] initWithCollectionViewLayout:self];
    }
    return self;
}

- (void)prepareLayout{
    
    [super prepareLayout];
    
    CGSize contentSize = [self collectionViewContentSize];
    NSArray *items = [super layoutAttributesForElementsInRect:CGRectMake(0, 0, contentSize.width, contentSize.height)];
    
    if (items.count != self.dynamicAnimator.behaviors.count) {
        [self.dynamicAnimator removeAllBehaviors];
        
        for (UICollectionViewLayoutAttributes *item in items) {
            UIAttachmentBehavior *springBehavior = [[UIAttachmentBehavior alloc] initWithItem:item attachedToAnchor:item.center];
            springBehavior.length = 0.f;
            springBehavior.damping = 1.f;
            springBehavior.frequency = 6.8f;
            
            [self.dynamicAnimator addBehavior:springBehavior];
        }
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    return [self.dynamicAnimator itemsInRect:rect];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [self.dynamicAnimator layoutAttributesForCellAtIndexPath:indexPath];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds{
    CGFloat scrollDelta = newBounds.origin.y - self.collectionView.bounds.origin.y;
    CGPoint touchLocation = [self.collectionView.panGestureRecognizer locationInView:self.collectionView];
    
    for (UIAttachmentBehavior *springBehavior in self.dynamicAnimator.behaviors) {
        CGPoint anchorPoint = springBehavior.anchorPoint;
        CGFloat touchDistance = fabsf(touchLocation.y - anchorPoint.y);
        CGFloat resistanceFactor = 0.002;
        
        UICollectionViewLayoutAttributes *attributes = springBehavior.items.firstObject;
       
        CGPoint center = attributes.center;
        
        float resistedScroll = scrollDelta * touchDistance * resistanceFactor;
        float simpleScroll = scrollDelta;
        
        float actualScroll = MIN(abs(simpleScroll), abs(resistedScroll));
        if(simpleScroll < 0){
            actualScroll *= -1;
        }
        
        center.y += actualScroll;
        attributes.center = center;
        
        [self.dynamicAnimator updateItemUsingCurrentState:attributes];
    }
    
    return NO;
}

-(void)dealloc{
    [self.dynamicAnimator removeAllBehaviors];
    self.dynamicAnimator = nil;
}

@end
