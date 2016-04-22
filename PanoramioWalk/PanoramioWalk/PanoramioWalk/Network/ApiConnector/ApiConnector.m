//
//  ApiConnector.m
//  PanoramioWalk
//
//  Created by rost on 21.04.16.
//  Copyright © 2016 Rost Gress. All rights reserved.
//

#define PANORAMIO_API_URL   @"http://www.panoramio.com/map/get_panoramas.php?set=full&from=0&to=1&size=medium&mapfilter=true"


#import "ApiConnector.h"
#import <CoreLocation/CoreLocation.h>
#import <UIKit/UIKit.h>


@interface ApiConnector () <NSURLSessionDelegate>

@end


@implementation ApiConnector

#pragma mark - initWithCallback:
- (id)initWithCallback:(ApiConnectorCallback)block {
    if (self = [super init])
        self.callbackBlock = block;
    
    return self;
}
#pragma mark -


#pragma mark - loadPhotoWithParams:
- (void)loadPhotoWithParams:(NSDictionary *)params {

    CLLocation *minLocation = params[@"min"];
    CLLocation *maxLocation = params[@"max"];

    double minX = minLocation.coordinate.latitude;
    double minY = minLocation.coordinate.longitude;
    
    double maxX = maxLocation.coordinate.latitude;
    double maxY = maxLocation.coordinate.longitude;
    
    NSString *urlString = [NSString stringWithFormat:@"%@&minx=%f&miny=%f&maxx=%f&maxy=%f", PANORAMIO_API_URL, minX, minY, maxX, maxY];
    NSURL *requestURL = [NSURL URLWithString:urlString];
    
    NSURLSessionConfiguration *sessionConfig = nil;
    NSURLSession *urlSession                 = nil;

    [UIApplication sharedApplication].minimumBackgroundFetchInterval = UIApplicationBackgroundFetchIntervalMinimum;
    
    sessionConfig                               = [NSURLSessionConfiguration backgroundSessionConfiguration:@"com.PanoramioWalk"];
    sessionConfig.discretionary                 = YES;
    sessionConfig.HTTPAdditionalHeaders         = @{ @"Accept"  : @"application/json"};
    sessionConfig.HTTPMaximumConnectionsPerHost = 1;
    
    urlSession  = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];

    NSMutableURLRequest *requestToApi = [NSMutableURLRequest requestWithURL:requestURL];
    requestToApi.HTTPMethod = @"GET";
    
    NSURLSessionDownloadTask *downloadTask = [urlSession downloadTaskWithRequest:requestToApi];
    
    [downloadTask resume];
}
#pragma mark -


#pragma mark - URLSession:downloadTask:didFinishDownloadingToURL:
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {    
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)downloadTask.response;
    NSDictionary *httpResponse = [response allHeaderFields];

    if ([[httpResponse allValues] count] > 0) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSError *fileManagerError  = nil;

        NSArray *pathsArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docsPath  = pathsArray[0];

        NSString *photosCustomPath = [docsPath stringByAppendingPathComponent:@"/PanoramioPhotos/"];

        if (![fileManager fileExistsAtPath:photosCustomPath]) {
            [fileManager createDirectoryAtPath:photosCustomPath withIntermediateDirectories:NO attributes:nil error:&fileManagerError];
        }

        photosCustomPath =  [photosCustomPath stringByAppendingFormat:@"/%@",[[downloadTask response] suggestedFilename]];
 
        if ([fileManager fileExistsAtPath:photosCustomPath]) {
            NSLog([fileManager removeItemAtPath:photosCustomPath error:&fileManagerError]?@"Old file was deleted":@"File not deleted");
        }

        BOOL fileCopied = [fileManager moveItemAtPath:[location path] toPath:photosCustomPath error:&fileManagerError];
        NSLog(fileCopied ? @"File copied" : @"File not copied");
        
        NSData *jsonData = [[NSFileManager defaultManager] contentsAtPath:photosCustomPath];
        NSError *jsonError = nil;
        NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData
                                                                   options:NSJSONReadingMutableLeaves
                                                                     error:&jsonError];
        
        if (!jsonObject) {
            NSLog(@"Parsing JSON error: %@", jsonError);
            self.callbackBlock(jsonError);
        } else {
            NSArray *photosArray = jsonObject[@"photos"];
            
            if ([photosArray count] > 0) {
                NSDictionary *receivedPhoto = @{@"photo_id"       : photosArray[0][@"photo_id"],
                                                @"photo_file_url" : photosArray[0][@"photo_file_url"]};
                self.callbackBlock(receivedPhoto);
            } else {
                self.callbackBlock(nil);
            }
        }
    }
}
#pragma mark -

@end
