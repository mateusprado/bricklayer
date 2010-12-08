
@implementation ProjectCreate: CPObject
{
    var mainView;
}
-(void)setMainClass:(id)mCls
{
    mainCls = mCls;
}

-(void)connectionDidFinishLoading:(CPURLConnection)connection
{
    [mainCls.addName setStringValue:@""];
    [mainCls.addRepository setStringValue:@""];
    [mainCls.addBranch setStringValue:@""];
    [mainCls.addVersion setStringValue:@""];
    [mainCls.addBuildCmd setStringValue:@""];
    [mainCls.addInstallCmd setStringValue:@""];

    [mainCls.addPanel performClose:self];

    [mainCls getProjects];
}

@end
