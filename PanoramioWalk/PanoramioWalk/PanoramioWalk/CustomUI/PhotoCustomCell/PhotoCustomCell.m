//
//  PhotoCustomCell.m
//  PanoramioWalk
//
//  Created by rost on 21.04.16.
//  Copyright © 2016 Rost Gress. All rights reserved.
//

#import "PhotoCustomCell.h"


@implementation PhotoCustomCell


#pragma mark - Constructor
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.photoImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.photoImageView.contentMode  = UIViewContentModeScaleAspectFit;
        
        NSDictionary *viewsValues = @{@"photoImageView"  : self.photoImageView};
        
        NSArray *subViewsFormats = @[@"H:|-(5)-[photoImageView]-(5)-|",
                                     @"V:|-(5)-[photoImageView]-(5)-|"];
        
        [self addViews:viewsValues toSuperview:self.contentView withConstraints:subViewsFormats];
    }
    
    return self;
}
#pragma mark -


#pragma mark - addViews:toSuperview:withConstraints:
- (void)addViews:(NSDictionary *)views toSuperview:(UIView *)superview withConstraints:(NSArray *)formats {
    for (UIView *view in views.allValues) {
        [superview addSubview:view];
        view.translatesAutoresizingMaskIntoConstraints = NO;
    }
    
    for (NSString *formatString in formats) {
        [superview addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:formatString
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
    }
}
#pragma mark -

@end
