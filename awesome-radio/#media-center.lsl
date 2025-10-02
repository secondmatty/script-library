// ===== Configuration section. Feel free to alter these settings ======//

// If you want to have multiple notecards with different sets of
// stations in your radio you can use this variable to specify 
// which one should be loaded
string  RADIO_NOTECARD = "Stations";


// ====== Script starts here, don't change anything beyond this line =======
/*

    Script Name: awesome-radio/#media-center.lsl
    
    Description: 
    Reads a notcard with Radio station names and URLs,
    presents a menu on click and sets the parcel audio stream
    url to the url of the selcted station
    
    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.
    
    Version History:
        10/01/2025: Initial 
    
*/

string  SEPARATOR = "=";            // character to separate title from URL
integer RADIO_CHANNEL;

list    RADIO_MENU_ITEMS = [];      // Radio menu items
list    RADIO_MEDIA_URLS = [];      // list of radio URLs
list    RADIO_MEDIA_NAMES = [];     // list of radio names
key     RADIO_QUERYID;              // query id for TV_NOTECARD query
integer RADIO_LINE = 0;             // current TV_NOTECARD line
integer RADIO_INITIALIZED = 0;      // initialization flag
integer RADIO_INDEX = 0;            // menu item index
integer RADIO_PAGE = 1;
integer RADIO_PAGES = 0;

string  CURRENT_STATION = "";

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
    RADIO_MENU_ITEMS = [];
    RADIO_MEDIA_URLS = [];
    RADIO_MEDIA_NAMES = [];
    RADIO_LINE = 0;
    RADIO_INITIALIZED = 0;
    RADIO_INDEX = 0;
    RADIO_PAGE = 1;
    RADIO_PAGES = 0;

    // Query for notecards
    RADIO_QUERYID = llGetNotecardLine(RADIO_NOTECARD, RADIO_LINE);
}

setAudioStream(string MEDIA_FILE)
{
    llSetParcelMusicURL(MEDIA_FILE);
}

radio_finished()
{
    llOwnerSay("Found " + (string)RADIO_INDEX + " Stations."); 
    RADIO_INITIALIZED=1;
    RADIO_PAGES = llCeil((float) RADIO_INDEX / 9.0);
    RADIO_PAGE = 1;
    llMessageLinked(LINK_THIS, 0, "RADIO_FINISHED", NULL_KEY);
}


showRadioMenu(key id)
{
    integer START = (RADIO_PAGE-1)*9;
    integer END = (RADIO_PAGE-1)*9 + 8;
    list ITEMS = llList2List(RADIO_MENU_ITEMS, START, END);
    string RADIO_MENU_TEXT= "Please select a station to listen to. ";
    integer x;
    
    if (CURRENT_STATION != "") 
    { 
        RADIO_MENU_TEXT += "You are currently listening to " + CURRENT_STATION;
    }
    
    RADIO_MENU_TEXT += "\n\n";
    
    for (x = 0; x < llGetListLength(ITEMS); x++)
    {
        RADIO_MENU_TEXT += llList2String(ITEMS,x) + " = " + llList2String(RADIO_MEDIA_NAMES, (integer)llList2String(ITEMS,x)-1 ) + "\n";
    }
        
    list NAV;
    
    if (RADIO_PAGE > 1)
    {
        NAV += ["<<"];
    } else
    {
        NAV += [" "];
    }
    
    NAV += [" "];
    
    if (RADIO_PAGE < RADIO_PAGES)
    {
        NAV += [">>"];
    } else
    {
        NAV += [" "];
    }

    llDialog(id, RADIO_MENU_TEXT, NAV + ITEMS, RADIO_CHANNEL);
}


default
{
    state_entry()
    {      
        RADIO_CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-3;  
        llListen(RADIO_CHANNEL, "", NULL_KEY, "");
    }

    // evaluate the return of the dataserver query
    dataserver(key query_id, string data) {

        if (query_id == RADIO_QUERYID) {
            if (data != EOF) {
                // skip empty lines
                if (data != "") {
                    // Split line into a list and validate the structure
                    list ENTRY = llParseString2List(data,[SEPARATOR],[]);
                    if (llGetListLength(ENTRY) != 2)
                    {
                        // invalid line structure
                        llOwnerSay("Skipped radio configuration line: " + data);
                    } else
                    {
                        // valid structure, add title + index to menu text,
                        // add URL to list of URLs and the title to the list
                        // of titles
                        ++RADIO_INDEX;
                        RADIO_MENU_ITEMS += [(string)(RADIO_INDEX)];
                        RADIO_MEDIA_NAMES += [Trim(llList2String(ENTRY,0)," ")];
                        RADIO_MEDIA_URLS += [Trim(llList2String(ENTRY,1)," ")];
                    }
                }
                // increase line index and read next TV_NOTECARD line             
                ++RADIO_LINE;
                RADIO_QUERYID = llGetNotecardLine(RADIO_NOTECARD, RADIO_LINE);
            }   else radio_finished(); // eof reached before the 10th valid line
        }
    } 
    
    listen(integer channel, string name, key id, string message)
    {
        // evaluate dialog response
        if (channel == RADIO_CHANNEL)
        {
            if (llListFindList(RADIO_MENU_ITEMS, [message]) != -1)  // verify dialog choice
            {
                // if response is within the list of menu items, set the video URL
                // and display the name of the video to local chat
                setAudioStream(llList2String(RADIO_MEDIA_URLS, (integer) message - 1));
                CURRENT_STATION = llList2String(RADIO_MEDIA_NAMES, (integer) message - 1);
                llWhisper(0, name + " switched the radio to channel \"" + CURRENT_STATION + "\".");
                showRadioMenu(id);          
            } else if (llListFindList(NAVIGATION_MENU, [message]) != -1)
            {
                if(message == "<<")
                {
                    if (RADIO_PAGE > 1) --RADIO_PAGE;
                    showRadioMenu(id);
                }
                else if(message == ">>")
                {
                    if (RADIO_PAGE < RADIO_PAGES) ++RADIO_PAGE;
                    showRadioMenu(id);
                }
            }
        } 
        
        
    }
    
    
    link_message(integer sender_num, integer num, string str, key id)
    {
        if      (str=="INITIALIZE") initialize();
        else if (str=="RADIO") showRadioMenu(id);
    }


}
