#import "PlaceMapViewController.h"
#import "Place.h"
#import "MapPin.h"
#import "ButtonTableViewController.h"
#import <CoreLocation/CoreLocation.h>

#define startLat @"40.809881"
#define startLong @"-73.959746"

@interface PlaceMapViewController ()

@property (nonatomic, strong) MKMapView *map;
@property (nonatomic, strong) NSMutableArray *placeArray;
@property (nonatomic, weak) CLLocationManager *locationManager;
@property CLLocationCoordinate2D userLocation;
@property (atomic) NSString *sid;

@end

@implementation PlaceMapViewController

@synthesize map = _map;
@synthesize placeArray = _placeArray;
@synthesize locationManager = _locationManager;
@synthesize userLocation = _userLocation;
@synthesize sid = _sid;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _placeArray = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _map = [[MKMapView alloc] initWithFrame:[[self view] frame]];
    [_map setDelegate:self];
    [self setTitle:@"TwitterMap"];
    _userLocation.latitude = [startLat doubleValue];
    _userLocation.longitude = [startLong doubleValue];
    _sid = @"0";
    
    CLLocationCoordinate2D startLocation;
    startLocation.latitude = [startLat floatValue];
    startLocation.longitude = [startLong floatValue];
    MKCoordinateSpan span = MKCoordinateSpanMake(0.42, 0.42);
    MKCoordinateRegion region = MKCoordinateRegionMake(startLocation, span);
    [_map setRegion:region];
    
    [[self view] addSubview:_map];
	// Do any additional setup after loading the view.
    
    NSRunLoop *runloop = [NSRunLoop currentRunLoop];
    NSTimer *timer = [NSTimer timerWithTimeInterval:10 target:self selector:@selector(updateData:) userInfo:nil repeats:YES];
    [runloop addTimer:timer forMode:NSRunLoopCommonModes];
    [runloop addTimer:timer forMode:UITrackingRunLoopMode];
}

-(void)updateData:(NSTimer *)sender
{
//    [_placeArray removeAllObjects];
    [_map removeAnnotations:[_map annotations]];
    [self getPlacesForLocation:[_map centerCoordinate]];
    NSLog(@"updateData called");
}

-(void)getPlacesForLocation:(CLLocationCoordinate2D)location
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error){
        if (granted) {
            
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            
            // Check if the users has setup at least one Twitter account
            
            if (accounts.count > 0)
            {
                ACAccount *twitterAccount = [accounts objectAtIndex:0];
                
                // Creating a request to get the info about a user on Twitter

                NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];

                [parameters setObject:@"new" forKey:@"q"];  // ******* you may try ny, e, or %40 for better search result ******
                [parameters setObject:@"100" forKey:@"count"];
                [parameters setObject:@"mixed" forKey:@"return_type"];
                [parameters setObject:@"true" forKey:@"include_entities"];
//                NSLog(@"_sid = %@", _sid);
                [parameters setObject:_sid forKey:@"since_id"];
                NSString *formattedLat = [NSString stringWithFormat:@"%0.2f", _userLocation.latitude];
                NSString *formattedLong = [NSString stringWithFormat:@"%0.2f", _userLocation.longitude];
                [parameters setObject:[NSString stringWithFormat:@"%@,%@,200mi",formattedLat, formattedLong] forKey:@"geocode"];
                
                SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/search/tweets.json"] parameters:parameters];
                
                
                [twitterInfoRequest setAccount:twitterAccount];
                
                // Making the request
                
                [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
                 {
                    NSDictionary *tweetDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                    if(error) { NSLog(@"Error getting data: %@", [error description]); return; }
                    
                    // update the max_id of last request to update the since_id of the next request
                    NSDictionary *searchMeta = [tweetDict objectForKey:@"search_metadata"];
                    _sid = [searchMeta objectForKey:@"max_id_str"];
                    
                    NSArray *tweetArray = [tweetDict objectForKey:@"statuses"];
                    for(NSDictionary *tweetDict in tweetArray)
                    {
                        id geo = [tweetDict objectForKey:@"geo"];
                        
                        if ( [geo isKindOfClass:[NSDictionary class]] ) {
                            
                            NSDictionary *user = [tweetDict objectForKey:@"user"];
                            
                            Place *newPlace = [[Place alloc] init];
                            
                            [newPlace setName:[user objectForKey:@"name"]];
                            
                            [newPlace setUser_id:[user objectForKey:@"id_str"]];
                            
                            [newPlace setTid:[tweetDict objectForKey:@"id_str"]];
                            
                            [newPlace setText:[tweetDict objectForKey:@"text"]];
                            
                            [newPlace setImageUrl:[user objectForKey:@"profile_image_url"]];
                            
                            [newPlace setTs:[tweetDict objectForKey:@"created_at"]];
                            
                            
                            NSArray *coordinate = [geo objectForKey:@"coordinates"];
                            CLLocationCoordinate2D placeLocation;
                            placeLocation.latitude = [[coordinate objectAtIndex:0] floatValue];
                            placeLocation.longitude = [[coordinate objectAtIndex:1] floatValue];
                            [newPlace setLocation:placeLocation];
                            
                            [_placeArray addObject:newPlace];
                        }
                    }
//                    NSString *msg = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//                    NSLog(@"%@", msg);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self putPinsOnMap];
                    });
                }];
            }
        } else {
            NSLog(@"No access granted");
        }
    }];
}

-(void)putPinsOnMap
{
    NSString *msg = [[NSString alloc] initWithFormat:@"Number of pins in the map is %d.\nTo cancel the alert, comment out line 173 in PlaceMapViewController.m please.", [_placeArray count]];
//    NSLog(@"count %d", [_placeArray count]);
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"This is for your grading convenience. You may change search keyword for better result in line 91."
                                                      message:msg
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
    [message show];
    for(Place *place in _placeArray)
    {
        MapPin *pin = [[MapPin alloc] init];
        
        [pin setUser_id:[place user_id]];
        [pin setName:[place name]];
        [pin setText:[place text]];
        [pin setLocation:[place location]];
        [pin setTid:[place tid]];
        [pin setTs:[place ts]];
        [pin setImageUrl:[place imageUrl]];
        
        [pin setTitle:[place name]];
        [pin setSubtitle:[place text]];
        [pin setCoordinate:[place location]];
        [_map addAnnotation:pin];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - MKMapViewDelegate methods

-(void)startLocationManager
{
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate=self;
    locationManager.desiredAccuracy=kCLLocationAccuracyBestForNavigation;
    [locationManager startUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    CLLocationCoordinate2D coord = [newLocation coordinate];
    NSLog(@"location changed");
    NSLog(@"latitude %+.6f, longitude %+.6f\n", coord.latitude, coord.longitude);
    _userLocation.latitude = coord.latitude;
    _userLocation.longitude = coord.longitude;
}

- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray *)locations {
    // If it's a relatively recent event, turn off updates to save power
    CLLocation* location = [locations lastObject];
//    NSDate* eventDate = location.timestamp;
//    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    NSLog(@"location changed");
    NSLog(@"latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
    _userLocation.latitude = location.coordinate.latitude;
    _userLocation.longitude = location.coordinate.longitude;
//    if (abs(howRecent) < 15.0) {
//        // If the event is recent, do something with it.
//        NSLog(@"latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
//        _userLocation.latitude = location.coordinate.latitude;
//        _userLocation.longitude = location.coordinate.longitude;
//    }
}

-(void)mapViewDidFinishLoadingMap:(MKMapView *)mapView
{
    if([_placeArray count] == 0)
    {
        [self getPlacesForLocation:[_map centerCoordinate]];
    }
//    NSLog(@"before updataData");
}

- (void)mapView:(MKMapView *)sender didSelectAnnotationView:(MKAnnotationView *)aView {
    // need to load image here!
/*
    if ([aView.leftCalloutAccessoryView isKindOfClass:[UIImageView class]]) {
        NSURL *thumbnailURL = [NSURL URLWithString:[video thumbnailURL]];
        NSError *error = nil;
        NSURLResponse *response = nil;
        NSData *thumbnailData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:thumbnailURL] returningResponse:&response error:&error];
        
        if(error) {
            NSLog(@"Error getting thumbnail data: %@", [error description]);
        }
        
        UIImage *thumbnail = [UIImage imageWithData:thumbnailData];
        [video setThumbnail:thumbnail];
        numberOfThumbnailRequests++;
     
        UIImageView *imageView = (UIImageView *)aView.leftCalloutAccessoryView;
        imageView.image = NULL; // if you do this in a GCD queue, be careful, views are reused!
    }
     */
}

-(MKAnnotationView *)mapView:(MKMapView *)sender
           viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *identifier = @"MapPin";
    if([annotation isKindOfClass:[MapPin class]])
    {
        MKPinAnnotationView *newPin = (MKPinAnnotationView *)[_map dequeueReusableAnnotationViewWithIdentifier:identifier];
        if(newPin == nil)
        {
            newPin = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
        }
        else
        {
            [newPin setAnnotation:annotation];
        }

        UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [rightButton setTitle:annotation.title forState:UIControlStateNormal];
        newPin.rightCalloutAccessoryView = rightButton;
        
        [newPin setEnabled:YES];
        [newPin setPinColor:MKPinAnnotationColorRed];
        [newPin setCanShowCallout:YES];
        [newPin setAnimatesDrop:YES];
        return newPin;
    }
    return nil;
}

//- (void)mapView:(MKMapView *)sender
// annotationView:(MKAnnotationView *)aView calloutAccessoryControlTapped:(UIControl *)control {
//    NSURL *thumbnailURL = [NSURL URLWithString:[video thumbnailURL]];
//    NSError *error = nil;
//    NSURLResponse *response = nil;
//    NSData *thumbnailData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:thumbnailURL] returningResponse:&response error:&error];
//    
//    if(error) {
//        NSLog(@"Error getting thumbnail data: %@", [error description]);
//    }
//    
//    UIImage *thumbnail = [UIImage imageWithData:thumbnailData];
//    [video setThumbnail:thumbnail];
//    numberOfThumbnailRequests++;
//}

- (void) buttonPressed:(UIButton *) sender
{
    NSLog(@"annotation button called");
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)sender.superview.superview;
    MapPin *annotation = (MapPin *)annotationView.annotation;
//    NSLog(@"%@", annotation.name);

    ButtonTableViewController *btnView = [[ButtonTableViewController alloc] initWithMapPin:annotation];
    [[self navigationController] pushViewController:btnView animated:YES];
}

@end