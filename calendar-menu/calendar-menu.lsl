/*
    Script Name: Calendar Menu
    
    Description: 
    Provides bookmarks to caledars specified above. Supports 
    up to 3 calendars in up to 3 timezones.
    
    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.
    
    Version History:
        10/04/2025.1: Initial 
*/

// ===== Configuration section. Feel free to alter these settings ======

// Specify up to three calendars by Name and URL
list CALENDAR_NAMES=["MELD","FCC","Realm"];
list CALENDAR_BASE_URLS=[
    "https://calendar.google.com/calendar/u/0/embed?src=1f51b7dd1a046b95184855b6dae000d658b433157231877fdc58cfc2668a8143@group.calendar.google.com",
    "https://calendar.google.com/calendar/u/0/embed?src=fccinsl@gmail.com",
    "https://calendar.google.com/calendar/u/0/embed?src=0027412020c76c7b253e5fef4ef8d3b5d8afa11eaf855b5c05486a8635d138ac@group.calendar.google.com"
    ];

// Specify up to three timezones by Name and TZ value
list TIMEZONE_NAMES = ["SLT", "CET"];

// TZ identifier for each zone. A list of all timezones and 
// their specification acn be found here:
// https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
list TIMEZONES = ["America/Los_Angeles", "Europe/Berlin"];

// Amount of seconds the dialog listener should be active
float DIALOG_TIMEOUT = 60.0;

// Additional text to be displayed
string DIALOG_TEXT = "This menu provides links to the calendars of The Realm, FCC and the MELD 2025.";


// ====== Script starts here, don't change anything beyond this line =======

integer CHANNEL;
integer LISTEN_HANDLE = -1;

list CALENDAR_MENU = [];
list CALENDAR_URLS = [];
string CURRENT_TIMEZONE_NAME;
string CURRENT_TIMEZONE;

show_dialog(key id)
{
    string text = "";
    if (DIALOG_TEXT != "") 
    {
        text += "\n" + DIALOG_TEXT + "\n";
    }

    if (LISTEN_HANDLE == -1) LISTEN_HANDLE = llListen(CHANNEL, "", "", "");
    llSetTimerEvent(DIALOG_TIMEOUT);
    llDialog(id, text + "\n" + "Selected timezone: " + CURRENT_TIMEZONE_NAME, CALENDAR_MENU + TIMEZONE_NAMES , CHANNEL);
}

integer verify_configuration()
{
    if (llGetListLength(CALENDAR_NAMES) > 3 || llGetListLength(CALENDAR_BASE_URLS) > 3)
    {
        llOwnerSay("Configuration Error: To many calendars. This calendar menu supports a maximum of 3 calendars");
        return FALSE; 
    }

    if (llGetListLength(CALENDAR_NAMES) != llGetListLength(CALENDAR_BASE_URLS))
    {
        llOwnerSay("Configuration Error: Number of calendar names and URLs doesn't match");
        return FALSE; 
    }

    if (llGetListLength(TIMEZONE_NAMES) > 3 || llGetListLength(TIMEZONES) > 3)
    {
        llOwnerSay("Configuration Error: To many timezones. This calendar menu supports a maximum of 3 timezones");
        return FALSE; 
    }

    if (llGetListLength(TIMEZONE_NAMES) != llGetListLength(TIMEZONES))
    {
        llOwnerSay("Configuration Error: Number of timezones names and TZ identifiers doesn't match");
        return FALSE; 
    }

    return TRUE;
}

default
{
    state_entry()
    {
        if (verify_configuration()==FALSE) return;
        
        string CET = "&ctz=Europe/Berlin";
        string SLT = "&ctz=America/Los_Angeles";
        string AGENDA = "&mode=agenda";
        string WEEK = "&mode=week";
        string MONTH = "&mode=month";
        
        integer length = llGetListLength(CALENDAR_NAMES);
        integer i = 0;
        do
        {
            string calendar_name = llList2String(CALENDAR_NAMES, i);
            CALENDAR_MENU += calendar_name + " Agenda";
            CALENDAR_MENU += calendar_name + " Week";
            CALENDAR_MENU += calendar_name + " Month";
        } while(++i < length);        
       
        i = 0; 
        do
        {
            string calendar_base_url = llList2String(CALENDAR_BASE_URLS, i);
            CALENDAR_URLS += calendar_base_url + AGENDA;
            CALENDAR_URLS += calendar_base_url + WEEK;
            CALENDAR_URLS += calendar_base_url + MONTH;
        } while(++i < length);     
        
        CURRENT_TIMEZONE_NAME = llList2String(TIMEZONE_NAMES, 0);
        CURRENT_TIMEZONE = llList2String(TIMEZONES, 0);
        
        CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-3; 
        
        llOwnerSay("Calendar menu ready.");
    }

    touch_start(integer total_number)
    {
        show_dialog(llDetectedKey(0)); 
    }
        
    listen(integer channel, string name, key id, string message)
    {
        llSetTimerEvent(0);
        llListenRemove(LISTEN_HANDLE);
        LISTEN_HANDLE =-1;
            
        integer max_calendar_index = llGetListLength(CALENDAR_NAMES) * 3;
        if (channel != CHANNEL) return;

        integer selected_index = (llListFindList(CALENDAR_MENU + TIMEZONE_NAMES, [message]));
        if (selected_index == -1)  return;
        
        if (selected_index < max_calendar_index) 
        {
            string url = llList2String(CALENDAR_URLS, selected_index) + "&ctz=" + CURRENT_TIMEZONE;
            string item = llList2String(CALENDAR_MENU, selected_index) + " (" + CURRENT_TIMEZONE_NAME + ")";
            
            llLoadURL(id,item,url);
        } 
        else if (selected_index >= max_calendar_index) 
        {
            CURRENT_TIMEZONE_NAME = llList2String(TIMEZONE_NAMES, selected_index - max_calendar_index); 
            CURRENT_TIMEZONE = llList2String(TIMEZONES, selected_index - max_calendar_index);
            show_dialog(id);
        } 
    }
    
   timer()
    {
        if (LISTEN_HANDLE != -1)
        {
            llListenRemove(LISTEN_HANDLE);
            LISTEN_HANDLE = -1;
            llSetTimerEvent(0.0);
        }
    }    
}

