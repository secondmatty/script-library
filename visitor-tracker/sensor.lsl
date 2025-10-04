/*
    Script Name: Sensor
    
    Description: 
    Detects avatars entering a spefic radius of the seonsor.
    Uses message queuing and linked prim messaging to trigger 
    notification from separate script in same prim.
    
    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.
    
    Version History:
        10/03/2025.1: Initial 
*/
// ====== Configuration section. Feel free to alter these settings ======

//  minimum and maximum amount of meters on Z axis to detect (relative to sensor position)
integer MAXZ = 20; 
integer MINZ = 20; 

// distance to detect in meter
float RANGE = 25.0;

// rate how often sensor should check for new visitors in seconds
float RATE = 1.0; 

// ===== Script starts here, don't change anything beyond this line =====

list visitor_list; 
list current_list; 

float maxZ = 0.0; 
float minZ = 0; 

list NOTOFICATION_QUEUE = [];

string get_timestamp()
{
    // "YYYY-MM-DDThh:mm:ss.ff..fZ" to "MM-DD-YYYY hh:mm:ss"
    list parsed_timestamp = llParseString2List(llGetTimestamp(),["-",":","."],["T"]); 
    string formated_timestamp = "";
    formated_timestamp += llList2String(parsed_timestamp, 1) + "-";
    formated_timestamp += llList2String(parsed_timestamp, 2) + "-";
    formated_timestamp += llList2String(parsed_timestamp, 0) + " ";
    formated_timestamp += llList2String(parsed_timestamp, 4) + ":";
    formated_timestamp += llList2String(parsed_timestamp, 5) + ":";
    formated_timestamp += llList2String(parsed_timestamp, 6) + " UTC";
    return formated_timestamp;
}

push_notification(string text) 
{ 
    NOTOFICATION_QUEUE += text + " (" + get_timestamp() + ")";
    llMessageLinked(LINK_THIS,0, "NEW_NOTIFICATION", "");
}

string pull_notification() 
{
    if(llGetListLength(NOTOFICATION_QUEUE) > 0)
    {
        // send first item from queue to notification script 
        // and remove it from queue
        string firstItem = llList2String(NOTOFICATION_QUEUE, 0);
        NOTOFICATION_QUEUE = llDeleteSubList(NOTOFICATION_QUEUE, 0, 0);
        return firstItem;
    } else {
        // empty string = end of list
        return "";
    }
}

integer is_on_list(string name, list avlist) 
{ 
    integer len = llGetListLength(avlist); 
    integer i; 
    for (i = 0; i < len; i++) 
    { 
        if (llList2String(avlist, i) == name) 
            return TRUE; 
    } 
    return FALSE; 
} 

initialize() 
{  
    vector rezPos = llGetPos(); 
    maxZ = rezPos.z + MAXZ; 
    minZ = rezPos.z - MINZ; 

    llSensorRepeat( "", "", AGENT, RANGE, TWO_PI, RATE ); 
} 

detect_changes(list detected) 
{ 
    string textEntered = ""; 
    string textExited = ""; 
    integer enterCount = 0; 
    integer exitCount = 0; 
    integer len; 
    integer i; 

    len = llGetListLength(detected); 
    for (i = 0; i < len; i++) 
    { 
        string name = llList2String(detected, i); 
        if (is_on_list(name, current_list)==FALSE) 
        { 
            current_list += name; 
            if (enterCount > 0) textEntered += ", "; 
            textEntered += name; 
            enterCount++; 
        } 
    } 
    
    len = llGetListLength(current_list); 
    for (i = 0; i < len; i++) 
    { 
        string name = llList2String(current_list, i); 
        if (is_on_list(name, detected)==FALSE) 
        { 
            if (exitCount > 0) textExited += ", "; 
            textExited += name; 
            exitCount++; 
        } 
    } 
    
    current_list = []; 
    len = llGetListLength(detected); 
    for (i = 0; i < len; i++) 
    { 
        string name = llList2String(detected, i); 
        current_list += name; 
    } 
    
    string msg = ""; 
    if (enterCount > 0) 
    { 
        msg = "Entered: "+textEntered; 
        if (exitCount > 0) 
            msg = "\nExited: "+textExited; 
    } 
    else if (exitCount > 0) 
        msg = "Exited: "+textExited; 
    if (msg != "") push_notification(msg); 
} 

default 
{ 
    state_entry() 
    { 
        initialize(); 
    } 
     
    on_rez(integer param) 
    { 
        llResetScript(); 
    } 

    sensor(integer number_detected) 
    { 
        list detected = []; 
        vector pos = llGetPos(); 
        integer i; 
         
        for (i = 0; i < number_detected; i++) 
        { 
            vector dpos = llDetectedPos(i); 
            if (llGetLandOwnerAt(dpos)==llGetLandOwnerAt(llGetPos  ())) 
            { 
                string detected_name = llDetectedName(i); 
                string detected_key = llDetectedKey(i); 
                integer i = llGetAgentInfo(detected_key); 
     
                if ((dpos.x >= 0 && dpos.x <= 256) && 
                    (dpos.y >= 0 && dpos.y <= 256) && 
                    (dpos.z >= minZ) && (dpos.z <= maxZ)) 
                { 
                    detected += detected_name; 
                } 
            } 
        } 
         
        detect_changes(detected); 
    } 
     
    no_sensor() 
    { 
        detect_changes([]); 
    } 
    
    link_message(integer sender_num, integer num, string str, key id)
    {
        if (num == 0  && str=="GET_NOTIFICATION") 
        {
            // notification scripts ask us for next message from the queue
            string notification = pull_notification();
            if (notification != "") llMessageLinked(LINK_THIS, 1, notification, llGetOwner());
        }
    }
} 