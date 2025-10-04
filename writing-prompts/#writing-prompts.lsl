/*
    Script Name: Writing Prompts
    
    Description: 
    Reads a list of writing prompts from a notecard and issues 
    a random one into the local chat every time someone clicks the prim.
    
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

// Name of the config file to read. You can have multiple in the inventory
// e.g. for different topics but only the prompts stored in THIS notecard
// will be served.
string  PROMPT_NOTECARD = "Prompts";

//  Sound to play when prompt is given. Set to "" to disable sound effect
string SOUND_EFFECT = "slapscream";

//  Volume of the sound. Valid values are between 0.0 (inaudible) and 1.0 (full volume)
float  SOUND_VOLUME = 1.0;


// ===== SCript starts here, don't change anything beyond this line =====

integer PROMPT_CHANNEL;
list    PROMPT_LIST = [];           // list of prompts
key     PROMPT_QUERYID;              // query id for notecard query
integer PROMPT_LINE = 0;             // current notecard line
integer PROMPT_COUNT = 0;            // total notecard line count
integer PROMPT_INITIALIZED = 0;      // initialization flag

list shift_left(list mylist) {
    integer len = llGetListLength(mylist);
    if (len > 0) 
    {
        string firstItem =  llList2String(mylist, 0);
        mylist=llDeleteSubList(mylist, 0, 0);
        return mylist+firstItem;
    }
    return [];
}

issue_prompt() {
    if(PROMPT_INITIALIZED!=1) return;
    
    llSay(0, llList2String(PROMPT_LIST, 0));
    PROMPT_LIST=shift_left(PROMPT_LIST);
    
    if (SOUND_EFFECT != "") {
        llPlaySound(SOUND_EFFECT, SOUND_VOLUME);
    }
}

initialize()
{
    // reset all vairables
    PROMPT_LIST = [];
    PROMPT_LINE = 0;
    PROMPT_INITIALIZED = 0;
    PROMPT_COUNT = 0;

    // Query for notecard
    PROMPT_QUERYID = llGetNotecardLine(PROMPT_NOTECARD, PROMPT_LINE);
}

initialize_finished()
{
    llOwnerSay("Found " + (string)PROMPT_COUNT + " prompts."); 
    PROMPT_INITIALIZED = 1;
    PROMPT_LIST = llListRandomize(PROMPT_LIST, 0);
    llMessageLinked(LINK_THIS, 0, "GIVER_FINISHED", NULL_KEY);
}

default
{
    state_entry()
    {      
        PROMPT_CHANNEL = (((integer)("0x"+llGetSubString((string)llGetKey(),-8,-1)) & 0x3FFFFFFF) ^ 0xBFFFFFFF)-3;  
        llListen(PROMPT_CHANNEL, "", NULL_KEY, "");
    }

    // evaluate the return of the dataserver query
    dataserver(key query_id, string data) {
        if (query_id == PROMPT_QUERYID) {
            if (data != EOF) {
                // skip empty lines
                if (data != "") {
                   ++PROMPT_COUNT;
                    PROMPT_LIST += data;
                }
                // increase line index and read next TV_NOTECARD line             
                ++PROMPT_LINE;
                PROMPT_QUERYID = llGetNotecardLine(PROMPT_NOTECARD, PROMPT_LINE);
            }   else initialize_finished(); // eof reached before the 10th valid line
        }
    } 
    

    link_message(integer sender_num, integer num, string str, key id)
    {
        if      (str=="INITIALIZE") initialize();
        else if (str=="TOUCH")      issue_prompt();
    }
}
