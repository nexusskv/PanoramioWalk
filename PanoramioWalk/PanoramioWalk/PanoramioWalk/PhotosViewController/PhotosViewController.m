//
//  PhotosViewController.m
//  PanoramioWalk
//
//  Created by rost on 21.04.16.
//  Copyright © 2016 Rost Gress. All rights reserved.
//

#define NAV_BAR_BACKGROUND_COLOR    [UIColor colorWithRed:240.0f/255.0f green:210.0f/255.0f blue:183.0f/255.0f alpha:1.0f]
#define TABLE_BACKGROUND_COLOR      [UIColor colorWithRed:241.0f/255.0f green:238.0f/255.0f blue:214.0f/255.0f alpha:1.0f]
#define USER_DISTANCE               100


#import "PhotosViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "PhotoCustomCell.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "ApiConnector.h"


@interface PhotosViewController () <UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate>

@property (strong, nonatomic) UITableView *photosTable;
@property (strong, nonatomic) NSArray *photosArray;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSDictionary *requestParams;
@end


@implementation PhotosViewController

#pragma mark - View life cycle
- (void)loadView {
    [super loadView];
    
    self.title = @"Panoramio Walk";
    
    self.navigationController.navigationBar.barTintColor = NAV_BAR_BACKGROUND_COLOR;
    self.view.backgroundColor                            = TABLE_BACKGROUND_COLOR;
   
    
    UIButton *startWalkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    startWalkButton.frame = CGRectMake(0.0f, 0.0f, 50.0f, 42.0f);
    [startWalkButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [startWalkButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [startWalkButton setTitle:@"Start" forState:UIControlStateNormal];
    
    [startWalkButton addTarget:self action:@selector(startButtonSelector:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *startWalkItem = [[UIBarButtonItem alloc] initWithCustomView:startWalkButton];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"updateLocationWasStarted"]) {
        BOOL buttonIsSelected = [[[NSUserDefaults standardUserDefaults] objectForKey:@"updateLocationWasStarted"] boolValue];
        startWalkButton.selected = buttonIsSelected;
    }
    
    [self setStartButtonState:startWalkButton];
    
    UIBarButtonItem *negativeFixedItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                  target:nil
                                                                                  action:nil];
    negativeFixedItem.width = -17.0f;
    self.navigationItem.rightBarButtonItems = @[negativeFixedItem, startWalkItem];
    
    self.photosTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.photosTable.delegate            = self;
    self.photosTable.dataSource          = self;
    self.photosTable.backgroundColor     = TABLE_BACKGROUND_COLOR;
    self.photosTable.separatorStyle      = UITableViewCellSeparatorStyleSingleLine;
    self.photosTable.tableFooterView     = [[UIView alloc] initWithFrame:CGRectZero];

    
    NSArray *constrFormats = @[@"H:|[photosTable]|",
                               @"V:|[photosTable]|"];
    
    [self addViews:@{@"photosTable" : self.photosTable} toSuperview:self.view withConstraints:constrFormats];
}
#pragma mark -


#pragma mark - startButtonSelector:
- (void)startButtonSelector:(UIButton *)sender {
    if (sender.tag == 0) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate           = self;
        self.locationManager.desiredAccuracy    = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter     = USER_DISTANCE;
        
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
            [self.locationManager requestAlwaysAuthorization];
        if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
            [self.locationManager requestWhenInUseAuthorization];

        [self startUpdateLocation];
    } else {
        [self stopUpdateLocation];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@(sender.isSelected) forKey:@"updateLocationWasStarted"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self setStartButtonState:sender];
}
#pragma mark -


#pragma mark - setStartButtonState:
- (void)setStartButtonState:(UIButton *)sender {
    if (sender.isSelected) {
        sender.selected = NO;
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
    } else {
        sender.selected = YES;
        [sender setTitle:@"Start" forState:UIControlStateNormal];
    }
}
#pragma mark -


#pragma mark - startUpdateLocation
- (void)startUpdateLocation {
    [self.locationManager startUpdatingLocation];
    [self.locationManager startMonitoringSignificantLocationChanges];
}
#pragma mark -


#pragma mark - stopUpdateLocation
- (void)stopUpdateLocation {
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}
#pragma mark -


#pragma mark - Panoramio ApiСonnnector method
- (void)sendRequestToPanoramioApiWithParams:(NSDictionary *)params {
    __weak __typeof(self)weakSelf = self;
    ApiConnector *apiConnector = [[ApiConnector alloc] initWithCallback:^(id resultObject) {
        if ([resultObject isKindOfClass:[NSDictionary class]]) {
            if ([[resultObject allValues] count] > 0) {
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                
                NSMutableArray *refreshPhotosArray = [NSMutableArray arrayWithObject:resultObject];
                
                if ([strongSelf.photosArray count] > 0)
                    [refreshPhotosArray addObjectsFromArray:strongSelf.photosArray];
                
                strongSelf.photosArray = refreshPhotosArray;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.photosTable reloadData];
                });
            }
        }
        
        [self startUpdateLocation];
    }];
    
    [apiConnector loadPhotoWithParams:params];
}
#pragma mark - 


#pragma mark - TableView dataSource & delegate methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.photosArray count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(PhotoCustomCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (cell.tag == indexPath.row)
        [cell.photoImageView sd_setImageWithURL:[NSURL URLWithString:self.photosArray[indexPath.row][@"photo_file_url"]]
                               placeholderImage:[UIImage imageNamed:@"placeholder.png"]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"cellIdentifier";
    
    PhotoCustomCell *cell = (PhotoCustomCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell     = [[PhotoCustomCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.tag = indexPath.row;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 210.0f;
}
#pragma mark -


#pragma mark - CoreLocation delegate methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    if ([locations count] > 0) {
        CLLocation *newLocation = locations.lastObject;
        
        if (!self.requestParams) {
            self.requestParams = @{@"min" : newLocation};
        } else {
            CLLocationDistance calculateDistanseInMeters = [newLocation distanceFromLocation:self.requestParams[@"min"]];
            
            if (calculateDistanseInMeters >= USER_DISTANCE) {
                CLLocation *minLocation = self.requestParams[@"min"];
                self.requestParams = @{@"min" : minLocation,
                                       @"max" : newLocation};
                
                [self sendRequestToPanoramioApiWithParams:self.requestParams];
                
                self.requestParams = @{@"min" : newLocation};
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self showAlert:@"Current location error!" withMessage:error.description];
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


#pragma mark - showAlert:withMessage:
- (void)showAlert:(NSString *)title withMessage:(NSString *)message {
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:message
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction *action) {}];
        
        [alertController addAction:defaultAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [[[UIAlertView alloc] initWithTitle:title
                                    message:message
                                   delegate:nil
                          cancelButtonTitle:@"Ok"
                          otherButtonTitles:nil] show];
    }
}
#pragma mark -

@end
