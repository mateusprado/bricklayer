@import <AppKit/CPTableView.j>

@implementation TableDataSource: CPObject
{
    CPDictionary tbData;
    id _target;
}

- (void)initWithData:(CPData)data
{
    tbData = data;
}

- (void)setTarget:(id)target
{
    _target = target;
}

- (CPInteger)numberOfRowsInTableView:(id)sender
{
    return [tbData count] + 1;
}

- (CPInteger)tableView:(id)aTableView objectValueForTableColumn:(id)tableColumn row:(id)aRow
{
    if (aRow == 0) {
        return "PROJECTS";
    }
    return [tbData[aRow - 1] objectForKey:[tableColumn identifier]];
}

- (BOOL)tableView:(CPTableView)aTableView isGroupRow:(int)aRow
{
    return aRow === 0;
}

- (void)tableViewSelectionDidChange:(id)notification
{
    var selection = [[notification object] selectedRow];
    [_target loadProject:tbData[selection - 1]];
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)aRow
{
    if (aRow === 0) {
       return NO;
    }
    else {
        return YES;
    }
}

/**
    var urlRequest = [CPURLRequest requestWithURL:"/ctrl/?action=transaction&type=in&desc=Test&value=10.0&tags=test1,test2"];
    [urlRequest setHTTPMethod:"GET"];
    var connection = [CPURLConnection connectionWithRequest:urlRequest delegate:self];
*/
@end

@implementation BuildsDataSource: CPObject
{
    CPDictionary tbData;
    id tableView;
}

-(void)connection:(CPConnection)aConn didReceiveData:(CPString)data
{
    tbData = [];
    var cpData = [[[CPData alloc] initWithRawString:data] JSONObject];
    for (i = 0; i < cpData.length; i++) {
        tbData[i] = [CPDictionary dictionaryWithJSObject:cpData[i] recursively:NO];
    }
    [tbData sortUsingDescriptors:[[CPSortDescriptor sortDescriptorWithKey:@"build" ascending:NO]]];
    [tableView reloadData];
}

- (CPInteger)numberOfRowsInTableView:(id)sender
{
    return [tbData count];
}

- (void)setTableView:(id)view
{
    tableView = view;
}

- (CPInteger)tableView:(id)aTableView objectValueForTableColumn:(id)tableColumn row:(id)aRow
{

    return [tbData[aRow] objectForKey:[tableColumn identifier]];
}

- (void)tableViewSelectionDidChange:(id)notification
{
    var selection = [[notification object] selectedRow];
}

- (BOOL)tableView:(CPTableView)aTableView shouldSelectRow:(int)aRow
{
        return YES;
}

- (void)tableView:(CPTableView)aTableView sortDescriptorsDidChange:(CPArray)oldDescriptors
{
    var newDescriptors = [aTableView sortDescriptors];
    [tbData sortUsingDescriptors:newDescriptors];
	[aTableView reloadData];
}

@end
