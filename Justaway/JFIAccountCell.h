#import <UIKit/UIKit.h>
#import "JFIAccount.h"

@interface JFIAccountCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *screenNameLabel;
@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic) NSString *themeName;

- (void)setLabelTexts:(JFIAccount *)account;

@end
