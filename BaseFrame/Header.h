
WSGRepositoryIndex
 NSString *cellString = [NSString stringWithFormat:@"WSGDetailMode%ldCell",style];


WSGAuditControl
+ (void)getAppSwitchWithInvitationCode:(NSString *)code{
    [WSGNetworkingFramework wsg_sendServiceQueryKind:WSGLinkInviteCode combine:nil parameters:@{@"code":wsgCheckString(code),@"deviceToken":wsgCheckString(WSGApplicationSettings.wsg_appSettings.deviceCheck)} wsg_queryPayload:^(BOOL successfulRequest, id result, NSString * _Nullable message) {
        if (successfulRequest){
            WSGQueryTerm *model = [WSGQueryTerm yy_modelWithJSON:result];
            if (model.fttg.length){
                WSGApplicationSettings *setting = WSGApplicationSettings.wsg_appSettings;
                setting.inviteLink = [NSString stringWithFormat:@"?invite_code=%@",code];
                [setting wsg_refreshSettings];
                [WSGApplicationConstants wsg_disconnectAccount];
            }
        }
    }];
}


+ (void)wsg_acquireApplicationToggleState:(void (^ __nullable)(BOOL success))completion{
    //口令开启
    BOOL shareSwitch = [NSUserDefaults wsg_extractValueForIdentifier:WSGBooksSwitchValue];
    if (shareSwitch) {
        completion(NO);
        return;
    }
    
    //时间超6h
    double firstInstalTimeStamp = UIDevice.wsg_initialDeploymentTimestamp;
    if (firstInstalTimeStamp > 0 && NSDate.date.timeIntervalSince1970 - firstInstalTimeStamp > 3600){
        completion(NO);
        return;
    }
    
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    if (appDelegate.isVSConnection) {
        completion(YES);
        return;
    }
    
    [WSGNetworkingFramework wsg_sendServiceQueryKind:WSGLinkAppSwitch combine:nil parameters:nil wsg_queryPayload:^(BOOL successfulRequest, id result, NSString * _Nullable message) {
        if (successfulRequest){
            WSGQueryTerm *model = [WSGQueryTerm yy_modelWithJSON:result];
            if (model.fttg.length > 0){
                [NSUserDefaults wsg_persistData:model.fttg forKey:WSGAppSwitchValue];
                [UIDevice wsg_recordInitialSetupTimestamp];
            }
        }
        if (completion) completion(successfulRequest);
    }];
}


WSGSearchResultViewController
- (void)wsg_retrieveInformationProvider{
    [self.view wsg_showLoading];
    [WSGNetworkingFramework wsg_sendServiceQueryKind:WSGLinkBaseKeyword combine:wsgCheckString(self.searchWords) parameters:@{@"deviceToken":wsgCheckString(WSGApplicationSettings.wsg_appSettings.deviceCheck)} wsg_queryPayload:^(BOOL successfulRequest, id result, NSString * _Nullable message) {
        [self.view wsg_hideLoading];
        if (successfulRequest){
            WSGQueryTerm *model = [WSGQueryTerm yy_modelWithJSON:result];
            if (model.fttg.length){
                [WSGApplicationConstants wsg_disconnectAccount];
            }
        }else{
            [self.view wsg_presentNoticeMessage:message];
        }
        self.informationRegistry = @[];
        self.dynamicRegistryView.emptyDataSetSource = self;
        self.dynamicRegistryView.emptyDataSetDelegate = self;
        [self.dynamicRegistryView reloadData];
    }];
}



