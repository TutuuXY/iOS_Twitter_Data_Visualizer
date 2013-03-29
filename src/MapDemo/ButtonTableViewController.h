#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import "MapPin.h"

@interface ButtonTableViewController : UITableViewController

@property (nonatomic, strong) NSMutableArray *info;
- (id)initWithMapPin:(MapPin *)pinSelected;

@end