/*
    Script Name: Alarm Clock
    
    Description: 
    A simple countdown timer alarm clock

    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.
    
    Version History:
        10/19/2025.1: Initial 
*/

// ===== Configuration section. Feel free to alter these settings ======
// The text engine in this script support placeholders placehoders.
// {x} = name of user who touched the prim
// {y} = current number of remaining minutes on the clock
// {z} = current mode of operation (Everyone, Group or Owner)

// Dialog text when time is idle
string MENU_TEXT = "Start the timer by clicking one of the minute buttons.";

// Text added to idle dialog if object was touched by it's owner
string OWNER_TEXT = " To toggle between Everyone, Group and Owner mode, press the Mode button.\n\nCurrent mode: {z}";
string RUNNING_TEXT = "Time is ticking!\n\nTime Remaining: {y} minute(s)";
string NOT_ALLOWED = "Sorry, you can't use this clock right now because it's restricted to {z} only.";

// Say/Whisper messages. Set it's value to "" to suppress a message.
string START_TEXT = "{x} started a {y} minutes timer.";
string END_TEXT   = "Time is up!";
string RESET_TEXT = "Timer was reset by {x}.";

// volume of the alert and windup sound. If set to 0.0 no sound will be played
float VOLUME = 1.0;

// if set to TRUE, script will whisper the texts in local. If set to FALSE it will say them
integer WHISPER = TRUE;

// ====== Script starts here, don't change anything beyond this line =======

integer CHANNEL;
integer TICK_INTERVAL = 60; // Seconds
integer REMAINING_MINUTES = 0;

list MODES = ["Everyone", "Group", "Owner"];
integer MODE_INDEX = 0;
string MODE = "Everyone";

notify(string text) {
    if(WHISPER == TRUE) {
        llWhisper(0, text);
    } else if (WHISPER == FALSE) {
        llSay(0, text);
    }
}

string replace_placeholders(string text, key id) {
    text = replace("{x}", llKey2Name(id), text);
    text = replace("{y}", (string)REMAINING_MINUTES, text);
    text = replace("{z}", MODE, text);
    return text;
}

string replace(string search, string replace, string subject)
{
    return llDumpList2String(llParseStringKeepNulls(subject,[search],[]),replace);
}

menu_idle(key toucher) {
        key owner = llGetOwner();
        
        if (
            (MODE == "Owner" && toucher != owner) ||
            (MODE == "Group" && !llSameGroup(toucher) && toucher != owner)
        ) {
            if (NOT_ALLOWED != "")  {
                string text = "\n" + NOT_ALLOWED + "\n";
                llDialog(toucher, replace_placeholders(text, toucher), [], CHANNEL);
            }
            return;
        }
        
        list choices =  ["10 Minutes", "15 Minutes", "30 Minutes"];
        string text = "\n" + MENU_TEXT;

        if (toucher == owner) {
            choices += ["Mode"];
            text += OWNER_TEXT;
        }

        text += "\n";
        text = replace_placeholders(text, toucher);
        
        llDialog(toucher, text, choices, CHANNEL);
        llListen(CHANNEL, "", NULL_KEY, "");
}

menu_running(key toucher) {
        list choices = [];

        key owner = llGetOwner();
       
        string text = "\n" + replace_placeholders(RUNNING_TEXT, toucher) + "\n";

        if (
            (MODE == "Group" && (llSameGroup(toucher) || toucher == owner)) ||
            (MODE == "Owner" && toucher == owner) ||
            (MODE == "Everyone")
        ) {
            choices += ["Reset"];
        }
             
        llDialog(toucher, text, choices, CHANNEL);
        llListen(CHANNEL, "", NULL_KEY, "");
}

default
{
    state_entry()
    {
        CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-3; 
        state idle;
    }
}

state idle
{
    touch_start(integer total_number)
    {
        key toucher = llDetectedKey(0);
        menu_idle(toucher);
    }
        
    listen(integer channel, string name, key id, string message)
    {
        if (channel != CHANNEL) return;
        if (message == "10 Minutes") {
            REMAINING_MINUTES = 10;
            notify(replace_placeholders(START_TEXT, id));
            state running;
        } else if (message == "15 Minutes") {
            REMAINING_MINUTES = 15;
            notify(replace_placeholders(START_TEXT, id));
            state running;
        } else if (message == "30 Minutes") {
            REMAINING_MINUTES = 30;
            notify(replace_placeholders(START_TEXT, id));
            state running;
        } else if (message == "Mode") {
            MODE_INDEX++;
            if (MODE_INDEX == 3) MODE_INDEX = 0;
            MODE = llList2String(MODES, MODE_INDEX);
            menu_idle(id);
        }
    }    
}

state running 
{
    state_entry()
    {
        if (VOLUME > 0.0) llPlaySound("windup", VOLUME);
        llSetTimerEvent(TICK_INTERVAL);
    }
    
    touch_start(integer total_number)
    {
        key toucher = llDetectedKey(0);
        key owner = llGetOwner();

        menu_running(toucher);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel != CHANNEL) return;
        if (message == "Reset") {
            REMAINING_MINUTES = 0;
            llSetTimerEvent(0);
            notify(replace_placeholders(RESET_TEXT, id));
            state idle;
        }
    }
        
   timer()
    {
        REMAINING_MINUTES--;
        if (REMAINING_MINUTES <= 0) {
            if (VOLUME > 0.0) llPlaySound("alarm", VOLUME);
            if (END_TEXT != "") notify(END_TEXT);
            state idle;
        }
    }#
}

