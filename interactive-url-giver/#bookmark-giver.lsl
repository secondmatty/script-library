// ===== Configuration section. Feel free to alter these settings ======//

// Tell the script which Notecard to retrieve the bookmarks from. 
// You can have multiple boookmar notecards in the inventory of the shelf,
// changing this setting allows for example to switch betweeen seasonal notecards 
string  BOOKMARK_NOTECARD = "Bookmarks"; // config file

// Message will be displayed in the pop-up dialog.
string  DIALOG_PROMPT = "This shelf will give you bookmarks to releases of some of our authors. Choose an item to receive a bookmark to the author's work in your local chat window";

// ====== SCript starts here, don't change anything beyond this line =======
/*

    Script Name: Bookmark Giver
    
    Description: 
    Reads a list of Bookmarks from a notecard in the inventory of the 
    prim and offers the content as menu. Delivers the chosen bookmark 
    as scripted instant message to the user. Utilizes asynchronous 
    push/pull message queueing to deal with the 2 second instant 
    message script delays.
    
    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.
    
    Version History:
        10/03/2025: Initial 
    
*/

string  SEPARATOR = "=";            // character to separate title from URL
integer GIVER_CHANNEL;

list    BOOKMARK_MENU_ITEMS = [];      // 1, 2, 3, ...
list    BOOKMARK_NAMES = [];     // Name/Description of the URL
list    BOOKMARK_URLS = [];            // The URL itself
key     NOTECARD_QUERYID;              // query id for TV_NOTECARD query
integer NOTECARD_LINE = 0;             // current TV_NOTECARD line
integer BOOKMARK_GIVER_INITIALIZED = 0;      // initialization flag
integer BOOKMARK_COUNT = 0;            // menu item count
integer MENU_PAGE = 1;
integer MENU_PAGES = 0;

list    NAVIGATION_MENU = ["<<"," ",">>"]; 

string Trim(string src, string chrs)//LSLEditor Unsafe, LSL Safe
{
    integer i = ~llStringLength(src);
    do ; while(i && ~llSubStringIndex(chrs, llGetSubString(src, i = -~i, i)));
    i = llStringLength(src = llDeleteSubString(src, 0x8000000F, ~-(i)));
    do ; while(~llSubStringIndex(chrs, llGetSubString(src, i = ~-i, i)) && i);
    return llDeleteSubString(src, -~(i), 0x7FFFFFF0);
}

initialize()
{
    // reset all vairables
    BOOKMARK_MENU_ITEMS = [];
    BOOKMARK_URLS = [];
    BOOKMARK_NAMES = [];
    NOTECARD_LINE = 0;
    BOOKMARK_GIVER_INITIALIZED = 0;
    BOOKMARK_COUNT = 0;
    MENU_PAGE = 1;
    MENU_PAGES = 0;

    // Query for notecards
    NOTECARD_QUERYID = llGetNotecardLine(BOOKMARK_NOTECARD, NOTECARD_LINE);
}

initilization_finished()
{
    llOwnerSay("Found " + (string)BOOKMARK_COUNT + " Bookmarks."); 
    BOOKMARK_GIVER_INITIALIZED=1;
    MENU_PAGES = llCeil((float) BOOKMARK_COUNT / 9.0);
    MENU_PAGE = 1;
    llMessageLinked(LINK_THIS, 0, "GIVER_FINISHED", NULL_KEY);
}


show_menu(key id)
{
    integer start = (MENU_PAGE-1)*9;
    integer end = (MENU_PAGE-1)*9 + 8;
    list items = llList2List(BOOKMARK_MENU_ITEMS, start, end);
    string menu_text= "\n" + DIALOG_PROMPT;
    integer x;
    
    menu_text += "\n\n";
    
    for (x = 0; x < llGetListLength(items); x++)
    {
        menu_text += llList2String(items,x) + " = " + llList2String(BOOKMARK_NAMES, (integer)llList2String(items,x)-1 ) + "\n";
    }
        
    list nav;

    if (MENU_PAGES > 1) 
    {    
        if (MENU_PAGE > 1)
        {
            nav += ["<<"];
        } else
        {
            nav += [" "];
        }
        
        nav += [" "];
        
        if (MENU_PAGE < MENU_PAGES)
        {
            nav += [">>"];
        } else
        {
            nav += [" "];
        }
    }

    llDialog(id, menu_text, nav + items, GIVER_CHANNEL);
}


default
{
    state_entry()
    {      
        GIVER_CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-3;  
        llListen(GIVER_CHANNEL, "", NULL_KEY, "");
    }

    // evaluate the return of the dataserver query
    dataserver(key query_id, string data) {

        if (query_id == NOTECARD_QUERYID) {
            if (data != EOF) {
                // skip empty lines
                if (data != "") {
                    // Split line into a list and validate the structure
                    list ENTRY = llParseString2List(data,[SEPARATOR],[]);
                    if (llGetListLength(ENTRY) != 2)
                    {
                        // invalid line structure
                        llOwnerSay("Skipped configuration line: " + data);
                    } else
                    {
                        // valid structure, add title + index to menu text,
                        // add URL to list of URLs and the title to the list
                        // of titles
                        ++BOOKMARK_COUNT;
                        BOOKMARK_MENU_ITEMS += [(string)(BOOKMARK_COUNT)];
                        BOOKMARK_NAMES += [Trim(llList2String(ENTRY,0)," ")];
                        BOOKMARK_URLS += [Trim(llList2String(ENTRY,1)," ")];
                    }
                }
                // increase line index and read next TV_NOTECARD line             
                ++NOTECARD_LINE;
                NOTECARD_QUERYID = llGetNotecardLine(BOOKMARK_NOTECARD, NOTECARD_LINE);
            }   else initilization_finished(); // eof reached before the 10th valid line
        }
    } 
    
    listen(integer channel, string name, key id, string message)
    {
        // evaluate dialog response
        if (channel == GIVER_CHANNEL)
        {
            if (llListFindList(BOOKMARK_MENU_ITEMS, [message]) != -1)  // verify dialog choice
            {
                string url = llList2String(BOOKMARK_URLS, (integer) message - 1);
                string text = llList2String(BOOKMARK_NAMES, (integer) message - 1);
                llLoadURL(id, text, url);
            } else if (llListFindList(NAVIGATION_MENU, [message]) != -1)
            {
                if(message == "<<")
                {
                    if (MENU_PAGE > 1) --MENU_PAGE;
                    show_menu(id);
                }
                else if(message == ">>")
                {
                    if (MENU_PAGE < MENU_PAGES) ++MENU_PAGE;
                    show_menu(id);
                }
            }
        } 
        
        
    }
    
    
    link_message(integer sender_num, integer num, string str, key id)
    {
        if      (num == 0 && str=="INITIALIZE") initialize();
        else if (num == 0 && str=="GIVE") show_menu(id);    
    }
}
