// ===== Configuration section. Feel free to alter these settings ======//

//  Set this to 1 if only owner and group should be served
integer GROUP_ONLY_MODE=0;


// ====== Script starts here, don't change anything beyond this line =======
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
        10/01/2025: Initial 
    
*/

integer CHANNEL;
integer GIVER_INITIALIZED=0;

initialize()
{
    CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-1;             
    GIVER_INITIALIZED=0;
    llOwnerSay("Initializing script..."); 
    llSetTimerEvent(5);
}


update_initilization_status()
{
    // notify user once all submodules are initialized
    if (GIVER_INITIALIZED == 1)
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
        if (GIVER_INITIALIZED!=1) return;
        key id = llDetectedKey(0);
        if (GROUP_ONLY_MODE == 1) {
            if (id == llGetOwner() || llSameGroup(id))
            {
                llMessageLinked(LINK_THIS,0, "GIVE", id);
            } else {
                llDialog(id, "\n\nSorry but you are not allowed to operate this device", [], -9999987);
            }
        } else {
             llMessageLinked(LINK_THIS,0, "GIVE", id);
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
        if (str=="GIVER_FINISHED") 
        {
            // Item giver is done initializing.
            GIVER_INITIALIZED = 1; 
            update_initilization_status();
        }
        else if (str=="reset_request") initialize();
    }
    
    timer()
    {
        llSetTimerEvent(0);
        llMessageLinked(LINK_THIS, 0, "INITIALIZE", NULL_KEY);
    }
}
