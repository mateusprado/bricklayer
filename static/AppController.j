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
@import "ProjectCreate.j"
@import "Font.j"
@import "mustache.js"

var htmlTemplate = nil;

CPLogRegister(CPLogConsole);


@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTableView menuView;
    @outlet CPTableView buildView;
    @outlet CPWebView logView;
    @outlet CPPanel logPanel;

    @outlet CPPanel addPanel;
    @outlet CPTextField addName;
    @outlet CPTextField addRepository;
    @outlet CPTextField addBranch;
    @outlet CPTextField addVersion;
    @outlet CPTextField addBuildCmd;
    @outlet CPTextField addInstallCmd;
    @outlet CPButton addSave;

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

    @outlet CPTextField repoUrl;
    @outlet CPTextField repoUser;
    @outlet CPTextField repoPasswd;

    var dataSource;
    var font;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // This is called when the application is done loading.
    [self getProjects];
    var reloadTimer = [CPTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(dataReloader:) userInfo:self repeats:YES];
}

-(void)dataReloader:(id)sender
{
    if ([menuView selectedRow] > 0) {
        [self getProjects];
        [dataSource tableViewSelectionDidChange:[CPNotification notificationWithName:'menuView' object:menuView]];
    }
}

-(void)getProjects
{
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

    font = [Font alloc];

    [font setFontAttrs:projectLabel isTitle:YES];
    [font setFontAttrs:repositoryLabel isTitle:NO];
    [font setFontAttrs:branchLabel isTitle:NO];
    [font setFontAttrs:versionLabel isTitle:NO];
    [font setFontAttrs:lastTestingTagLabel isTitle:NO];
    [font setFontAttrs:lastStableTagLabel isTitle:NO];
    [font setFontAttrs:lastCommitLabel isTitle:NO];

    [repositoryField setDelegate:self];
    [branchField setDelegate:self];
    [versionField setDelegate:self];

    var column = [menuView tableColumnWithIdentifier:@"name"];
    var columnView = [column dataView];

    [font setMenuFontAttrs:columnView];

    [column setDataView:columnView];

    [menuView setBackgroundColor:[CPColor colorWithHexString:@"DEE4EA"]];
    [projectView setBackgroundColor:[CPColor colorWithHexString:@"DEE4EA"]];

    var build_column = [buildView tableColumnWithIdentifier:@"build"],
        descriptor_build = [CPSortDescriptor sortDescriptorWithKey:@"build" ascending:NO];
    [build_column setSortDescriptorPrototype:descriptor_build];

    var date_column = [buildView tableColumnWithIdentifier:@"date"],
        descriptor_date = [CPSortDescriptor sortDescriptorWithKey:@"date" ascending:NO];
    [date_column setSortDescriptorPrototype:descriptor_date];

    var version_column = [buildView tableColumnWithIdentifier:@"version"],
        descriptor_version = [CPSortDescriptor sortDescriptorWithKey:@"version" ascending:NO];
    [version_column setSortDescriptorPrototype:descriptor_version];

    [buildView setUsesAlternatingRowBackgroundColors:YES];
    [buildView setDoubleAction:@selector(rowDoubleClicked:)];
}

-(void)connection:(CPConnection)aConn didReceiveData:(CPString)data
{
    var selected = [menuView selectedRow];
    console.log(selected);
    if (selected == -1) {
        selected = 1;
    }

    dataSource = [TableDataSource alloc];

    [dataSource initWithData:[[CPData alloc] initWithRawString:data]];
    [dataSource setTarget:self];
    [menuView setDataSource:dataSource];
    [menuView setDelegate:dataSource];

    [menuView selectRowIndexes:[CPIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
}

-(void)loadProject:(JSONObject)projectInfo
{
    console.log("load project");
    [projectLabel setStringValue:projectInfo["name"]];
    [repositoryField setStringValue:projectInfo["git_url"]];
    [versionField setStringValue:projectInfo["version"]];
    [branchField setStringValue:projectInfo["branch"]];
    [lastTestingTagValue setStringValue:projectInfo["last_tag_testing"]];
    [lastStableTagValue setStringValue:projectInfo["last_tag_stable"]];
    [lastCommitValue setStringValue:projectInfo["last_commit"]];

    var buildsDataSource = [BuildsDataSource alloc];
    [buildsDataSource setTableView:buildView];

    var buildUrlRequest = [CPURLRequest requestWithURL:@"/build/" + projectInfo["name"]];
    [buildUrlRequest setHTTPMethod:"GET"];
    var connection = [CPURLConnection connectionWithRequest:buildUrlRequest delegate:buildsDataSource];

    [buildView setDataSource:buildsDataSource];
    [buildView setDelegate:buildsDataSource];

}

- (void) controlTextDidEndEditing:(id)sender
{
    var changedValue = [[sender object] stringValue];
    var textField = [sender object];
    var request = new CFHTTPRequest();

    request.open("PUT", "/project/" + [projectLabel stringValue], false);
    request.oncomplete = function()
    {
        if (request.success())
            console.log(request.responseText());
    }

    if (textField == versionField) {
        request.send("version=" + [versionField stringValue] + "\r\n");
    }
    else if (textField == repositoryField) {
        request.send("git_url=" + [repositoryField stringValue] + "\r\n");
    }
    else if (textField == branchField) {
        request.send("branch=" + [repositoryField stringValue] + "\r\n");
    }
}

- (IBAction)saveClicked:(id)sender
{
    var name = [addName stringValue],
        repository = [addRepository stringValue],
        branch = [addBranch stringValue],
        build_cmd = [addBuildCmd stringValue],
        install_cmd = [addInstallCmd stringValue],
        version = [addVersion stringValue];

    var repo_url = [repoUrl stringValue],
        repo_user = [repoUser stringValue],
        repo_passwd = [repoPasswd stringValue];

    var request = new CFHTTPRequest();

    if (name && repository && branch) {
        var postData = {'name': name, 'git_url': repository, 'branch': branch, 'version': version, 'build_cmd': build_cmd, 'install_cmd': install_cmd};
        var postDict = [CPDictionary dictionaryWithJSObject:postData];
        var keys = [postDict allKeys], k;
        var body = "1=1";
        var buildUrlRequest = [CPURLRequest requestWithURL:@"/project"];
        var projectCreate = [ProjectCreate alloc];

        for (k = 0; k < [keys count]; k++) {
            if ([postDict valueForKey:keys[k]] != '') {
                body += "&" + keys[k] + "=" + [postDict valueForKey:keys[k]];
            }
        }

        body += "\r\n";

        [buildUrlRequest setHTTPMethod:"POST"];
        [buildUrlRequest setHTTPBody:body];
        [buildUrlRequest setValue:"application/x-www-form-urlencoded" forHTTPHeaderField:"Content-Type"];

        [projectCreate setMainClass:self];

        var connection = [CPURLConnection connectionWithRequest:buildUrlRequest delegate:projectCreate];

        if (repo_url && repo_user && repo_passwd) {
            request.open("POST", "/repository/" + name, false);
            request.oncomplete = function()
            {
                if (request.success()) {
                    [repoUrl setStringValue:""];
                    [repoUser setStringValue:""];
                    [repoPasswd setStringValue:""];
                }

            }
            request.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
            request.send("repository_url="+repo_url+"&repository_user="+repo_user+"&repository_passwd="+repo_passwd+"\r\n");

        }
    }
    else {
        [addPanel performClose:self];
    }
}

-(void)rowDoubleClicked:(id)sender
{
    var delegate = [sender delegate];
    var rowData = [delegate.tbData[[sender selectedRow]]][0];
    var request = new CFHTTPRequest();
    var project = [projectLabel stringValue];
    var build_log = "";

    request.open("GET", "/static/buildlog.html", false);
    request.oncomplete = function()
    {
        if (request.success())
            htmlTemplate = request.responseText();
    }

    request.send("");

    request.open("GET", "/log/" + project + "/" + rowData['build'], false);
    request.oncomplete = function()
    {
        if (request.success())
            build_log = request.responseText();
    }

    request.send("");

    var htmlParsed = Mustache.to_html(htmlTemplate, {'build_log': build_log});
    [logView loadHTMLString:htmlParsed];
    [logPanel orderFront:self];
}

@end
