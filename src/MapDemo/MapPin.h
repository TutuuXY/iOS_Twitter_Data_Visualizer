#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MapPin : NSObject<MKAnnotation>

@property (nonatomic, strong) NSString *name, *text, *user_id, *tid, *ts, *imageUrl;
@property CLLocationCoordinate2D location;
@property (nonatomic, strong) NSString *title, *subtitle;
@property CLLocationCoordinate2D coordinate;

@end
