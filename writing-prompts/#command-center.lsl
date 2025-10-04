/*
    Script Name: Command Center
    
    Description: 
    Modular control script that communicates over the linked-prim
    messaging. It routes touch events to other business logic 
    scritps. Sends reset request to sub modules on inventory change and 
    can optionally be set to accept touch events by prim group and
    owner only.
    
    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.

    Version History:
        10/01/2025.1: Initial 
*/
// ====== Configuration section. Feel free to alter these settings ======

//  Set this to TRUE if only owner and group should be served
integer GROUP_ONLY_MODE=FALSE;


// ===== Script starts here, don't change anything beyond this line =====

integer CHANNEL;
integer GIVER_INITIALIZED=0;

initialize()
{
    CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-1;             
    GIVER_INITIALIZED=0;
    llOwnerSay("Initializing notecard giver..."); 
    llSetTimerEvent(5);
}


update_initialization_status()
{
    // notify user once all submodules are initialized
    if (GIVER_INITIALIZED == TRUE) 
        llOwnerSay("Initialization finished.");
}

default
{
    state_entry()
    {
        llSetText("", <1,1,1>,1.0);
        initialize();
        llListen(CHANNEL, "", NULL_KEY, "");
    }
    
    on_rez(integer start_param)
    {
        llResetScript();   
    }

    touch_start(integer total_number)
    {
        if (GIVER_INITIALIZED != TRUE) return;
        
        key id = llDetectedKey(0);
        if (GROUP_ONLY_MODE == TRUE) {
            if (id == llGetOwner() || llSameGroup(id))
            {
                llMessageLinked(LINK_THIS,0, "TOUCH", id);
            } else {
                llDialog(id, "\n\nSorry but you are not allowed to operate this device", [], -9999987);
            }
        } else {
             llMessageLinked(LINK_THIS,0, "TOUCH", id);
        }
    }


    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) 
        {
            llOwnerSay("Configuration change detected. Resetting!");
            initialize();
        }
    } 

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (str=="GIVER_FINISHED") {
            // Prompt giver is done initializing.
            GIVER_INITIALIZED = TRUE; 
            update_initialization_status();
        }
        else if (str=="RESET_REQUEST") 
            initialize();
    }
    
    timer()
    {
        llSetTimerEvent(0);
        llMessageLinked(LINK_THIS, 0, "INITIALIZE", NULL_KEY);
    }
}
