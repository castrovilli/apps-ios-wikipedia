//  Created by Monte Hurd on 2/10/14.

#import "LoginViewController.h"
#import "NavController.h"
#import "QueuesSingleton.h"
#import "LoginTokenOp.h"
#import "LoginOp.h"
#import "SessionSingleton.h"
#import "UIViewController+Alert.h"
#import "NSHTTPCookieStorage+CloneCookie.h"
#import "AccountCreationViewController.h"
#import "UIButton+ColorMask.h"

#define NAV ((NavController *)self.navigationController)

@interface LoginViewController (){

}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation LoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.navigationItem.hidesBackButton = YES;
    [self.createAccountButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [self.createAccountButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateSelected];
    [self.createAccountButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];

    UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress)];
    longPressRecognizer.minimumPressDuration = 1.0f;
    [self.view addGestureRecognizer:longPressRecognizer];

    if ([self.scrollView respondsToSelector:@selector(keyboardDismissMode)]) {
        self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    }
    
    [self.usernameField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.passwordField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];    
}

-(void)textFieldDidChange:(id)sender
{
    BOOL shouldHighlight = ((self.usernameField.text.length > 0) && (self.passwordField.text.length > 0)) ? YES : NO;
    [self highlightCheckButton:shouldHighlight];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameField) {
        [self.passwordField becomeFirstResponder];
    }else if(textField == self.passwordField) {
        [self save];
    }
    return YES;
}

-(void)highlightCheckButton:(BOOL)highlight
{
    UIButton *checkButton = (UIButton *)[NAV getNavBarItem:NAVBAR_BUTTON_CHECK];
    
    checkButton.backgroundColor = highlight ?
        [UIColor colorWithRed:0.19 green:0.70 blue:0.55 alpha:1.0]
        :
        [UIColor clearColor];
    
    [checkButton maskButtonImageWithColor: highlight ?
        [UIColor whiteColor]
        :
        [UIColor blackColor]
     ];
}

// Handle nav bar taps.
- (void)navItemTappedNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    UIView *tappedItem = userInfo[@"tappedItem"];

    switch (tappedItem.tag) {
        case NAVBAR_BUTTON_CHECK:
            [self save];
            break;
        case NAVBAR_BUTTON_X:
            [self hide];
            break;
        default:
            break;
    }
}

-(void)handleLongPress
{
    // Uncomment for presentation username/pwd auto entry
    // self.usernameField.text = @"montehurd";
    // self.passwordField.text = @"";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NAV.navBarMode = NAVBAR_MODE_LOGIN;
    
    [self highlightCheckButton:NO];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.usernameField becomeFirstResponder];

    // Listen for nav bar taps.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(navItemTappedNotification:) name:@"NavItemTapped" object:nil];
}

-(void)save
{
    [self loginWithUserName: self.usernameField.text
                   password: self.passwordField.text
                  onSuccess: ^{
                      [self performSelector:@selector(hide) withObject:nil afterDelay:1.25f];
                  } onFail: nil];
}

-(void)hide
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [self highlightCheckButton:NO];

    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NavItemTapped" object:nil];

    NAV.navBarMode = NAVBAR_MODE_SEARCH;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)loginWithUserName: (NSString *)userName
                password: (NSString *)password
               onSuccess: (void (^)(void))successBlock
                  onFail: (void (^)(void))failBlock
{
    [self showAlert:@""];

    if (!successBlock) successBlock = ^(){};
    if (!failBlock) failBlock = ^(){};

    /*
    void (^printCookies)() =  ^void(){
        NSLog(@"\n\n\n\n\n\n\n\n\n\n");
        for (NSHTTPCookie *cookie in [NSHTTPCookieStorage sharedHTTPCookieStorage].cookies) {
            NSLog(@"cookies = %@", cookie.properties);
        }
        NSLog(@"\n\n\n\n\n\n\n\n\n\n");
    };
     */
    
    //[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    
    LoginOp *loginOp =
    [[LoginOp alloc] initWithUsername: userName
                             password: password
                               domain: [SessionSingleton sharedInstance].domain
                      completionBlock: ^(NSString *loginResult){
                          
                          // Login credentials should only be placed in the keychain if they've been authenticated.
                          [SessionSingleton sharedInstance].keychainCredentials.userName = userName;
                          [SessionSingleton sharedInstance].keychainCredentials.password = password;
                          
                          //NSString *result = loginResult[@"login"][@"result"];
                          [self showAlert:loginResult];
                          
                          [[NSOperationQueue mainQueue] addOperationWithBlock:successBlock];
                          
                          [self cloneSessionCookies];
                          //printCookies();
                          
                      } cancelledBlock: ^(NSError *error){
                          
                          [self showAlert:error.localizedDescription];

                          [[NSOperationQueue mainQueue] addOperationWithBlock:failBlock];

                          
                      } errorBlock: ^(NSError *error){
                          
                          [self showAlert:error.localizedDescription];

                          [[NSOperationQueue mainQueue] addOperationWithBlock:failBlock];
                          
                      }];
    
    LoginTokenOp *loginTokenOp =
    [[LoginTokenOp alloc] initWithUsername: userName
                                  password: password
                                    domain: [SessionSingleton sharedInstance].domain
                           completionBlock: ^(NSString *tokenRetrieved){
                               
                               NSLog(@"loginTokenOp token = %@", tokenRetrieved);
                               loginOp.token = tokenRetrieved;
                               
                           } cancelledBlock: ^(NSError *error){
                               
                               [self showAlert:@""];

                               [[NSOperationQueue mainQueue] addOperationWithBlock:failBlock];
                               
                           } errorBlock: ^(NSError *error){
                               
                               [self showAlert:error.localizedDescription];

                               [[NSOperationQueue mainQueue] addOperationWithBlock:failBlock];
                               
                           }];
    
    loginTokenOp.delegate = self;
    loginOp.delegate = self;
    
    // The loginTokenOp needs to succeed before the loginOp can begin.
    [loginOp addDependency:loginTokenOp];
    
    [[QueuesSingleton sharedInstance].loginQ cancelAllOperations];
    [QueuesSingleton sharedInstance].loginQ.suspended = YES;
    [[QueuesSingleton sharedInstance].loginQ addOperation:loginTokenOp];
    [[QueuesSingleton sharedInstance].loginQ addOperation:loginOp];
    [QueuesSingleton sharedInstance].loginQ.suspended = NO;
}

-(void)cloneSessionCookies
{
    // Make the session cookies expire at same time user cookies. Just remember they still can't be
    // necessarily assumed to be valid as the server may expire them, but at least make them last as
    // long as we can to lessen number of server requests. Uses user tokens as templates for copying
    // session tokens. See "recreateCookie:usingCookieAsTemplate:" for details.

    NSString *domain = [SessionSingleton sharedInstance].domain;

    NSString *cookie1Name = [NSString stringWithFormat:@"%@wikiSession", domain];
    NSString *cookie2Name = [NSString stringWithFormat:@"%@wikiUserID", domain];
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] recreateCookie: cookie1Name
                                            usingCookieAsTemplate: cookie2Name
     ];
    
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] recreateCookie: @"centralauth_Session"
                                            usingCookieAsTemplate: @"centralauth_User"
     ];
}

- (IBAction)createAccountButtonPushed:(id)sender
{
    AccountCreationViewController *createAcctVC = [self.navigationController.storyboard instantiateViewControllerWithIdentifier:@"AccountCreationViewController"];
    [self.navigationController pushViewController:createAcctVC animated:YES];
}

@end
