#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface Place : NSObject

@property (nonatomic, strong) NSString *name, *text, *user_id, *tid, *ts, *imageUrl;
@property CLLocationCoordinate2D location;

@end
