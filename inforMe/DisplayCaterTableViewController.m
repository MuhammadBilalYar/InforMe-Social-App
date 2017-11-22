//
//  DisplayCaterTableViewController.m
//  inforMe
//
//  Created by BSSE on 12/06/2016.
//  Copyright © 2016 BSSE. All rights reserved.
//

#import "DisplayCatTableViewController.h"
#import "CategoryModal.h"
#import "SWRevealViewController.h"
#import "PictureTableViewCell.h"
#import "textTableViewCell.h"
#import "videoTableViewCell.h"
#include "loginUser.h"
#import "AudioTableViewCell.h"
#import "RestAPI.h"
#import "Status.h"

@interface DisplayCatTableViewController ()<RestAPIDelegate>{
    UINavigationBar *navBar;
}
@property(nonatomic,strong) RestAPI *respApi;
@end

@implementation DisplayCatTableViewController

{
    NSArray *subcribed;
    NSMutableArray *recivedData;
    float height;
    BOOL isSubcribed;
}
-(RestAPI *)respApi{
    if(!_respApi){
        _respApi=[[RestAPI alloc]init];
    }
    return _respApi;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    isSubcribed=NO;
    recivedData= [[NSMutableArray alloc]init];
    [self httpUserSubscription ];
    [self httpPostRequest];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([PictureTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([PictureTableViewCell class])];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([textTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([textTableViewCell class])];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([videoTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([videoTableViewCell class])];
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass([AudioTableViewCell class]) bundle:nil] forCellReuseIdentifier:NSStringFromClass([AudioTableViewCell class])];
}

-(void)viewDidAppear:(BOOL)animated{
    [self httpPostRequest];
    [self.tableView reloadData];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return recivedData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    height=0.0f;
    Status *s=[recivedData objectAtIndex:indexPath.row];
    self.title=s.CategoryName;
    if (s.AudioUrl.length>5) {
        height=380.0f;
        return [self AudioTableViewCell:tableView cellForRowAtIndexPath:indexPath];
    } else if(s.VideoUrl.length>5){
        height=480.0f;
        return [self videoTableViewCell:tableView cellForRowAtIndexPath:indexPath];
    }else if(s.ImageUrl.length>5){
        height=480.0f;
        return [self picturetTableViewCell:tableView cellForRowAtIndexPath:indexPath];
    }else{
        height=250.0f;
        return [self textTableViewCell:tableView cellForRowAtIndexPath:indexPath];
    }
    
}
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return height;
}
-(void) httpPostRequest{
    NSString *url= [NSString stringWithFormat:@"http://localhost/inforMe/getByCategory.php?CategoryId=%@",[CategoryModal getCat].catId];
    NSURL *requestUrl=[NSURL URLWithString:url];
    
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:requestUrl];
    
    [request setHTTPMethod:GET];
    self.respApi.delegate =self;
    [self.respApi httpRequest:request];
}

-(void) httpUserSubscription{
    isSubcribed=YES;
    NSString *url=[NSString stringWithFormat:@"http://localhost/inforMe/getSubcribed.php?UserId=%@",[loginUser getUser].userId];
    NSURL *requestUrl=[NSURL URLWithString:url];
    
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:requestUrl];
    
    [request setHTTPMethod:GET];
    
    self.respApi.delegate =self;
    [self.respApi httpRequest:request];
}
-(void)getRecivedData:(NSMutableData *)data sender:(RestAPI *)sender{
    NSError *error=nil;
    NSArray *rData=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (isSubcribed) {
        subcribed=rData;
        isSubcribed=NO;
    }else{
        Status *status;
        recivedData=[[NSMutableArray alloc]init];
        for (int i=0; i<rData.count; i++) {
            NSDictionary *sts=[rData[i] objectForKey:@"status"];
            for (NSDictionary *sub in subcribed) {
                if ([sub[@"Active"]isEqualToString:@"YES"] && [sub[@"CategoryId"] isEqualToString:sts[@"CategoryId"]]) {
                    status=[[Status alloc]initWithDict:rData[i]];
                    [recivedData addObject:status];
                    break;
                }
                else if([sub[@"Active"]isEqualToString:@"NO"]&& [sub[@"CategoryId"] isEqualToString:sts[@"CategoryId"]]){
                    break;
                }
            }
        }
        if (recivedData.count==0) {
            [self showAlertMessageInAlertStyle:@"information" setError:@"No Data in This Category"];
        }
    }
    [self.tableView reloadData];
}

- (UITableViewCell *)AudioTableViewCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AudioTableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([AudioTableViewCell class]) forIndexPath:indexPath];
    Status *s=[recivedData objectAtIndex:indexPath.row];
    cell.imgProfile.image=[UIImage imageNamed:s.userImageUrl];
    cell.txtProfileName.text=[NSString stringWithFormat:@"%@ %@",s.firstName,s.lastName ];
    cell.txtLocation.text=s.Address;
    cell.txtRemainingTime.text=s.UpdatingTime;
    cell.txtCategory.text=s.CategoryName;
    cell.txtNotesDetails.text=s.StatusText;
    cell.txtLike.text=s.StatusLike;
    cell.txtDislike.text=s.StatusDislike;
    cell.txtComment.text=s.feedBacks;
    cell.txtReport.text=s.Reports;
    cell.audioUrl=s.AudioUrl;
    cell.UserId =s.UserId;
    cell.StatusId=s.StatusId;
    cell.delegate = self;
    return cell;
}

- (UITableViewCell *)videoTableViewCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    videoTableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([videoTableViewCell class]) forIndexPath:indexPath];
    Status *s=[recivedData objectAtIndex:indexPath.row];
    cell.imgProfile.image=[UIImage imageNamed:s.userImageUrl];
    cell.txtProfileName.text=[NSString stringWithFormat:@"%@ %@",s.firstName,s.lastName ];
    cell.txtLocation.text=s.Address;
    cell.txtRemainingTime.text=s.UpdatingTime;
    cell.txtCategory.text=s.CategoryName;
    cell.txtNotesDetails.text=s.StatusText;
    cell.videoUrl=s.VideoUrl;
    cell.txtLike.text=s.StatusLike;
    cell.txtDislike.text=s.StatusDislike;
    cell.txtComment.text=s.feedBacks;
    cell.txtReport.text=s.Reports;
    cell.StatusId=s.StatusId;
    //    NSString *imgUrl=[NSString stringWithFormat:@"http://localhost/inforMe/img/%@",s.ImageUrl];
    //    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:imgUrl]] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    //        cell.imgProfile.image = [UIImage imageWithData:data];
    //    }];
    cell.delegate = self;
    return cell;
}

- (UITableViewCell *)picturetTableViewCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PictureTableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PictureTableViewCell class]) forIndexPath:indexPath];
    
    Status *s=[recivedData objectAtIndex:indexPath.row];
    cell.imgProfile.image=[UIImage imageNamed:s.userImageUrl];
    cell.txtProfileName.text=[NSString stringWithFormat:@"%@ %@",s.firstName,s.lastName ];
    cell.txtLocation.text=s.Address;
    cell.txtRemainingTime.text=s.UpdatingTime;
    cell.txtCategory.text=s.CategoryName;
    cell.txtNotesDetails.text=s.StatusText;
    cell.imgNotesPic.image=[UIImage imageNamed:s.ImageUrl];
    cell.txtLike.text=s.StatusLike;
    cell.txtDislike.text=s.StatusDislike;
    cell.txtComment.text=s.feedBacks;
    cell.txtReport.text=s.Reports;
    cell.StatusId=s.StatusId;
    cell.delegate = self;
    return cell;
}


-(void)loadNewScreen:(UITableViewController *)controller;
{
    [self presentViewController:controller animated:YES completion:nil];
}


- (UITableViewCell *)textTableViewCell:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    textTableViewCell *cell=[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([textTableViewCell class]) forIndexPath:indexPath];
    
    Status *s=[recivedData objectAtIndex:indexPath.row];
    cell.imgUserProfile.image=[UIImage imageNamed:s.userImageUrl];
    cell.txtUserName.text=[NSString stringWithFormat:@"%@ %@",s.firstName,s.lastName ];
    cell.txtLocation.text=s.Address;
    cell.txtRemainingTime.text=s.UpdatingTime;
    cell.txtCategory.text=s.CategoryName;
    cell.txtNotesText.text=s.StatusText;
    cell.btnLike.text=s.StatusLike;
    cell.btnDislike.text=s.StatusDislike;
    cell.btnComment.text=s.feedBacks;
    cell.btnReport.text=s.Reports;
    cell.StatusId=s.StatusId;
    cell.delegate = self;
    return cell;
}
- (IBAction)btnCancel:(id)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *ivc = [storyboard instantiateViewControllerWithIdentifier:@"Home"];
    [self presentViewController:ivc animated:NO completion:nil];
}
-(void)showAlertMessageInAlertStyle:(NSString *)Title setError:(NSString*)errorMessage{
    UIAlertController *alert=[UIAlertController alertControllerWithTitle:Title message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
                                                              UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
                                                              UIViewController *ivc = [storyboard instantiateViewControllerWithIdentifier:@"Home"];
                                                              [self presentViewController:ivc animated:NO completion:nil];

                                                          }];
    
    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
    
}
@end
