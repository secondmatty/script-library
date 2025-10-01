// ===== Configuration section. Feel free to alter these settings ======//

// This is the message displayed in the dialogue box.
string GIVER_WELCOME = "Please choose a notecard.";


// ====== Script starts here. Don't change anything beyond this line ======//
/*  
    Script Name: Notecard giver
    
    Description: 
    Scans inventory of prim for notecards and responds to "GIVE"
    command from command center script by providing a menu with 
    all notecards found to the user who triggered the event.
    Supports pagination and will re-scan the inventory on demand.
    
    Auhtor: Matt Briar (mattbriar), mattbriar.resident@gmail.com
    
    This script is distributed under CC BY License. You may distribute, 
    remix, adapt, and build upon the material in any medium or format, 
    so long as attribution is given to the creator. The license allows
    for commercial use.
    
    Version History:
        10/01/2025: Initial 
*/

integer GIVER_CHANNEL;
list    GIVER_MENU_ITEMS = [];      // Notecard menu items
list    GIVER_NOTECARD_NAMES = [];  // list of notecard names
integer GIVER_INITIALIZED = 0;      // initialization flag
integer GIVER_INDEX = 0;            // menu item index
integer GIVER_PAGE = 1;
integer GIVER_PAGES = 0;

list    NAVIGATION_MENU = ["<<"," ",">>"]; 

initialize()
{
    // reset all vairables
    GIVER_MENU_ITEMS = [];
    GIVER_NOTECARD_NAMES = [];
    GIVER_INITIALIZED = 0;
    GIVER_INDEX = 0;
    GIVER_PAGE = 1;
    GIVER_PAGES = 0;

    list    InventoryList;
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    
    string  ItemName;
    while (count--)
    {
        ItemName = llGetInventoryName(INVENTORY_NOTECARD, count);
        ++GIVER_INDEX;
        GIVER_MENU_ITEMS += [(string)(GIVER_INDEX)];
        GIVER_NOTECARD_NAMES += ItemName;
    }
    
    llOwnerSay("Found " + (string)GIVER_INDEX + " Notecards."); 
    GIVER_INITIALIZED=1;
    GIVER_PAGES = llCeil((float) GIVER_INDEX / 9.0);
    GIVER_PAGE = 1;
    llMessageLinked(LINK_THIS, 0, "GIVER_FINISHED", NULL_KEY);
}

showGiverMenu(key id)
{
    integer START = (GIVER_PAGE-1)*9;
    integer END = (GIVER_PAGE-1)*9 + 8;
    list ITEMS = llList2List(GIVER_MENU_ITEMS, START, END);
    string GIVER_MENU_TEXT = "\n" + GIVER_WELCOME +"\n\n";
    
    integer x;
    for (x = 0; x < llGetListLength(ITEMS); x++)
    {
        GIVER_MENU_TEXT += llList2String(ITEMS,x) + " = " + llList2String(GIVER_NOTECARD_NAMES, (integer)llList2String(ITEMS,x)-1 ) + "\n";
    }
        
    list NAV;
    
    if (GIVER_PAGE > 1)
    {
        NAV += ["<<"];
    } else
    {
        NAV += [" "];
    }
    
    NAV += [" "];
    
    if (GIVER_PAGE < GIVER_PAGES)
    {
        NAV += [">>"];
    } else
    {
        NAV += [" "];
    }

    llDialog(id, GIVER_MENU_TEXT, NAV + ITEMS, GIVER_CHANNEL);
}


default
{
    state_entry()
    {      
        GIVER_CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-3;  
        llListen(GIVER_CHANNEL, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        // evaluate dialog response
        if (channel == GIVER_CHANNEL)
        {
            if (llListFindList(GIVER_MENU_ITEMS, [message]) != -1)  // verify dialog choice
            {
                string ItemName = llList2String(GIVER_NOTECARD_NAMES, (integer) message - 1);
                llGiveInventory(id, ItemName);
            } else if (llListFindList(NAVIGATION_MENU, [message]) != -1)
            {
                if(message == "<<")
                {
                    if (GIVER_PAGE > 1) --GIVER_PAGE;
                    showGiverMenu(id);
                }
                else if(message == ">>")
                {
                    if (GIVER_PAGE < GIVER_PAGES) ++GIVER_PAGE;
                    showGiverMenu(id);
                }
            }
        } 
        
        
    }
     
    link_message(integer sender_num, integer num, string str, key id)
    {
        if      (str=="INITIALIZE") initialize();
        else if (str=="GIVE") showGiverMenu(id);
    }
}
