/*

    Script Name: awesome-radio/#main-script.lsl
    
    Description: 
    Modular control script that communicates over the linked-prim
    messaging. It routes touch events to other business logic 
    scritps. Sends reset request to sub modules on inventory change.
    Will only accept touch events by prim group and owner.
    
    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.
    
    Version History:
        10/01/2025.1: Initial 
    
*/

integer CHANNEL;           // dialog channel

integer RADIO_INITIALIZED = FALSE;

initialize()
{
    CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-1;             
    RADIO_INITIALIZED=0;
    llOwnerSay("Initializing Radio..."); 
    llSetTimerEvent(5);

}

update_initilization_status()
{
        if (RADIO_INITIALIZED == TRUE)
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
        if (RADIO_INITIALIZED == FALSE) return;

        key id = llDetectedKey(0);
        if (id == llGetOwner() || llSameGroup(id))
        {
            llMessageLinked(LINK_THIS,0, "RADIO", id);
        } else {
            llDialog(id, "\n\nSorry but you are not allowed to operate this device", [], -9999987);
        }
    }


    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) 
        {
            llOwnerSay("Configuration change detected. Resetting...");
            initialize();
        }
    } 

    link_message(integer sender_num, integer num, string str, key id)
    {
        if (str=="RADIO_FINISHED") {
            RADIO_INITIALIZED = TRUE;
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
