#import "ButtonTableViewController.h"

@interface ButtonTableViewController ()

@property (nonatomic, strong) NSString *imageUrl;
@property (nonatomic, strong) MapPin *now;

@end

@implementation ButtonTableViewController

@synthesize info = _info;
@synthesize now = _now;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        
    }
    return self;
}

- (id)initWithMapPin:(MapPin *)pin
{
    if (self) {

    } else {
        self = [super init];
    }
    
    //        NSLog(@"hello");
    _info = [[NSMutableArray alloc] init];
    self.imageUrl = [pin imageUrl];
    [_info addObject:[@"User Name : "  stringByAppendingString:[pin name]]];
    [_info addObject:[@"User ID : " stringByAppendingString:[pin user_id]]];
    [_info addObject:[@"Tweet ID : " stringByAppendingString:[pin tid]]];
    [_info addObject:[@"Timestamp : " stringByAppendingString:[pin ts]]];
    [_info addObject:[@"Tweet Content : " stringByAppendingString:[pin text]]];
    
    _now = pin;

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
//    NSLog(@"count of table rows is %d", [_info count]+2);
    return [_info count]+2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.textLabel.font = [UIFont fontWithName:@"ArialMT" size:11];
//    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 3;
    if ( indexPath.row==[_info count] ) {
        UIButton *rbtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        rbtn.frame = CGRectMake(0.0f, 0.2f, 320.0f, 44.0f);
        [rbtn addTarget:self action:@selector(retweet:) forControlEvents:UIControlEventTouchUpInside];

        [rbtn setTitle:@"Retweet" forState:UIControlStateNormal];
        [cell addSubview:rbtn];
        
    } else if ( indexPath.row==[_info count]+1 ) {
        UIButton *fbtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        fbtn.frame = CGRectMake(0.0f, 0.2f, 320.0f, 44.0f);
        [fbtn addTarget:self action:@selector(favorite:) forControlEvents:UIControlEventTouchUpInside];
        
        [fbtn setTitle:@"Favorite" forState:UIControlStateNormal];
        [cell addSubview:fbtn];
    } else if ( indexPath.row == 0) {
        [[cell textLabel] setText:[_info objectAtIndex:[indexPath row]]];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^
                       {
                           NSURL *url = [NSURL URLWithString:[self imageUrl]];
                           NSError *error = nil;
                           NSURLResponse *response = nil;
                           NSData *thumbnailData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:&error];
                           
                           if(error) {
                               NSLog(@"Error getting thumbnail data: %@", [error description]);
                           }
                           
                           UIImage *avatar = [UIImage imageWithData:thumbnailData];
                           dispatch_async(dispatch_get_main_queue(), ^
                                          {
                                              [[cell imageView] setImage:avatar];
                                              [cell setNeedsLayout];
                                          });
                       });
    } else {
        [[cell textLabel] setText:[_info objectAtIndex:[indexPath row]]];
    }
    // Configure the cell...
    
    return cell;
}

- (void) retweet:(UIButton *) sender
{
    NSLog(@"retweet clicked");
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
                
                NSString *url = [[NSString alloc] initWithFormat:@"https://api.twitter.com/1.1/statuses/retweet/%@.json",_now.tid];

                SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:url] parameters:parameters];
                
                [twitterInfoRequest setAccount:twitterAccount];
                
                // Making the request
                
                [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    
                    
//                    NSString *msg = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//                    NSLog(@"%@", msg);
                    
                    if(error) { NSLog(@"Error getting data: %@", [error description]); return; }

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([urlResponse statusCode] != 200) {
                            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Sorry, your request doesn't succeed."
                                                                              message:@"Please try again."
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                            [message show];
                            return ;
                        } else {
                            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Congratulations!"
                                                                              message:@"Retweet Successfully!"
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                            [message show];
                        }
                    });
                }];
            }
        } else {
            NSLog(@"No access granted");
        }
    }];
}

- (void) favorite:(UIButton *) sender
{
    NSLog(@"favorite clicked");
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
                [parameters setObject:_now.tid forKey:@"id"];
                [parameters setObject:@"true" forKey:@"include_entities"];
                
                NSString *url = [[NSString alloc] initWithFormat:@"https://api.twitter.com/1.1/favorites/create.json"];
                
                SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodPOST URL:[NSURL URLWithString:url] parameters:parameters];
                
                [twitterInfoRequest setAccount:twitterAccount];
                
                // Making the request
                
                [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                    
//                    NSString *msg = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
//                    NSLog(@"%@", msg);
                    
                    if(error) { NSLog(@"Error getting data: %@", [error description]); return; }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if ([urlResponse statusCode] != 200) {
                            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Sorry, your request doesn't succeed."
                                                                              message:@"Please try again."
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                            [message show];
                        } else {
                            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Congratulations!"
                                                                              message:@"Favorite Successfully!"
                                                                             delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                            [message show];
                        }
                    });
                }];
            }
        } else {
            NSLog(@"No access granted");
        }
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
