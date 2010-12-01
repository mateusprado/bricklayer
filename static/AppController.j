/*
 * AppController.j
 * static
 *
 * Created by You on November 16, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <AppKit/CPOutlineView.j>

@import "TableDataSource.j"

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTableView menuView;
    @outlet CPTableView buildView;
    @outlet CPView projectView;
    @outlet CPTextField projectLabel;
    @outlet CPTextField repositoryLabel;
    @outlet CPTextField repositoryField;
    @outlet CPTextField branchLabel;
    @outlet CPTextField branchField;
    @outlet CPTextField versionLabel;
    @outlet CPTextField versionField;

    @outlet CPTextField lastTestingTagLabel;
    @outlet CPTextField lastTestingTagValue;
    @outlet CPTextField lastStableTagLabel;
    @outlet CPTextField lastStableTagValue;
    @outlet CPTextField lastCommitLabel;
    @outlet CPTextField lastCommitValue;
    var dataSource;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    
    var urlRequest = [CPURLRequest requestWithURL:@"/project"];
    [urlRequest setHTTPMethod:"GET"];
    var connection = [CPURLConnection connectionWithRequest:urlRequest delegate:self];

}

- (void)awakeFromCib
{
    // This is called when the cib is done loading.
    // You can implement this method on any object instantiated from a Cib.
    // It's a useful hook for setting up current UI values, and other things. 
    
    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullBridge:YES];

    [self setFontAttrs:projectLabel isTitle:YES];
    [self setFontAttrs:repositoryLabel isTitle:NO];
    [self setFontAttrs:branchLabel isTitle:NO];
    [self setFontAttrs:versionLabel isTitle:NO];
    [self setFontAttrs:lastTestingTagLabel isTitle:NO];
    [self setFontAttrs:lastStableTagLabel isTitle:NO];
    [self setFontAttrs:lastCommitLabel isTitle:NO];
    
    var column = [menuView tableColumnWithIdentifier:@"name"];
    var columnView = [column dataView];
    
    [self setMenuFontAttrs:columnView]; 

    [column setDataView:columnView];

    [menuView setBackgroundColor:[CPColor colorWithHexString:@"DEE4EA"]]; 
    [projectView setBackgroundColor:[CPColor colorWithHexString:@"DEE4EA"]]; 
    
}

-(void)connection:(CPConnection)aConn didReceiveData:(CPString)data
{
    dataSource = [TableDataSource alloc];
    [dataSource initWithData:[[CPData alloc] initWithRawString:data]];
    [dataSource setTarget:self];
    [menuView setDataSource:dataSource];
    [menuView setDelegate:dataSource];

    [menuView selectRowIndexes:[CPIndexSet indexSetWithIndex:1] byExtendingSelection:NO];
}

-(void)loadProject:(JSONObject)projectInfo
{
    [projectLabel setStringValue:projectInfo["name"]]; 
    [repositoryField setStringValue:projectInfo["git_url"]];
    [versionField setStringValue:projectInfo["version"]];
    [branchField setStringValue:projectInfo["branch"]];
    [lastTestingTagValue setStringValue:projectInfo["last_tag_testing"]];
    [lastStableTagValue setStringValue:projectInfo["last_tag_stable"]];
    [lastCommitValue setStringValue:projectInfo["last_commit"]];
}

-(void)setFontAttrs:(id)view isTitle:(BOOL)title
{

    if(title)
    {
    //    [view setLineBreakMode:CPLineBreakByTruncatingTail];
    //    [view setFont:[CPFont boldSystemFontOfSize:12.0]];
    //    [view setVerticalAlignment:CPCenterVerticalTextAlignment];
    //    [view unsetThemeState:CPThemeStateSelectedDataView];
        [view setValue:[CPFont boldSystemFontOfSize:14.0]                     forThemeAttribute:"font"];
        [view setValue:[CPColor colorWithCalibratedWhite:125 / 255 alpha:1.0] forThemeAttribute:"text-color"];
        [view setValue:[CPColor colorWithCalibratedWhite:1 alpha:1]           forThemeAttribute:"text-shadow-color"];
        [view setValue:CGSizeMake(0,1)                                        forThemeAttribute:"text-shadow-offset"];
        [view setValue:CGInsetMake(1.0, 0.0, 0.0, 2.0)                        forThemeAttribute:"content-inset"];

    }
    else {
    //    [view setValue:[CPColor colorWithCalibratedRed:71/255 green:90/255 blue:102/255 alpha:1]           forThemeAttribute:"text-color"];
    //    [view setValue:[CPColor colorWithCalibratedWhite:1 alpha:1]           forThemeAttribute:"text-shadow-color"];
    //    [view setValue:CGSizeMake(0,1)                                        forThemeAttribute:"text-shadow-offset"];
    //    [view setValue:[CPColor colorWithCalibratedWhite:0 alpha:0.5]           forThemeAttribute:"text-shadow-color"];

        [view setLineBreakMode:CPLineBreakByTruncatingTail];
        [view setFont:[CPFont boldSystemFontOfSize:11.0]];
        [view setVerticalAlignment:CPCenterVerticalTextAlignment];
        [view unsetThemeState:CPThemeStateSelectedDataView];

        [view setValue:[CPColor colorWithCalibratedRed:71/255 green:90/255 blue:102/255 alpha:1]  forThemeAttribute:"text-color"];
        [view setValue:[CPColor colorWithCalibratedWhite:1 alpha:1]           forThemeAttribute:"text-shadow-color"];
        [view setValue:CGSizeMake(0,-1)                                       forThemeAttribute:"text-shadow-offset"];

    }
}

-(void)setMenuFontAttrs:(id)view
{
    [view setLineBreakMode:CPLineBreakByTruncatingTail];
    [view setFont:[CPFont boldSystemFontOfSize:11.0]];
    [view setVerticalAlignment:CPCenterVerticalTextAlignment];
    [view unsetThemeState:CPThemeStateSelectedDataView];

    [view setValue:[CPColor colorWithCalibratedRed:71/255 green:90/255 blue:102/255 alpha:1]           forThemeAttribute:"text-color"         inState:CPThemeStateTableDataView];
    [view setValue:[CPColor colorWithCalibratedWhite:1 alpha:1]           forThemeAttribute:"text-shadow-color"  inState:CPThemeStateTableDataView];
    [view setValue:CGSizeMake(0,1)                                        forThemeAttribute:"text-shadow-offset" inState:CPThemeStateTableDataView];

    [view setValue:[CPColor colorWithCalibratedWhite:1 alpha:1.0]         forThemeAttribute:"text-color"         inState:CPThemeStateTableDataView | CPThemeStateSelectedTableDataView];
    [view setValue:[CPColor colorWithCalibratedWhite:0 alpha:0.5]           forThemeAttribute:"text-shadow-color"  inState:CPThemeStateTableDataView | CPThemeStateSelectedTableDataView];
    [view setValue:CGSizeMake(0,-1)                                       forThemeAttribute:"text-shadow-offset" inState:CPThemeStateTableDataView | CPThemeStateSelectedTableDataView];

    [view setValue:[CPFont boldSystemFontOfSize:12.0]                     forThemeAttribute:"font"               inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
    [view setValue:[CPColor colorWithCalibratedWhite:125 / 255 alpha:1.0] forThemeAttribute:"text-color"         inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
    [view setValue:[CPColor colorWithCalibratedWhite:1 alpha:1]           forThemeAttribute:"text-shadow-color"  inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
    [view setValue:CGSizeMake(0,1)                                        forThemeAttribute:"text-shadow-offset" inState:CPThemeStateTableDataView | CPThemeStateGroupRow];
    [view setValue:CGInsetMake(1.0, 0.0, 0.0, 2.0)                        forThemeAttribute:"content-inset"      inState:CPThemeStateTableDataView | CPThemeStateGroupRow];    
}
@end
