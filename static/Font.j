@implementation Font: CPObject

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
