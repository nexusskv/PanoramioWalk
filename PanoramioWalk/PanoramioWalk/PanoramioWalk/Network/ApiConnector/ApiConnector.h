//
//  ApiConnector.h
//  PanoramioWalk
//
//  Created by rost on 21.04.16.
//  Copyright © 2016 Rost Gress. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ApiConnectorCallback)(id);


@interface ApiConnector : NSObject

@property (nonatomic, copy) ApiConnectorCallback callbackBlock;

- (id)initWithCallback:(ApiConnectorCallback)block;
- (void)loadPhotoWithParams:(NSDictionary *)params;

@end
