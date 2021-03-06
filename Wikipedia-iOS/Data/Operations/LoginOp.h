//  Created by Monte Hurd on 1/16/14.

#import "MWNetworkOp.h"

@interface LoginOp : MWNetworkOp

@property (strong, nonatomic) NSString *token;

- (id)initWithUsername: (NSString *)userName
              password: (NSString *)password
                domain: (NSString *)domain
       completionBlock: (void (^)(NSString *))completionBlock
        cancelledBlock: (void (^)(NSError *))cancelledBlock
            errorBlock: (void (^)(NSError *))errorBlock
;

@end
