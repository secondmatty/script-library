/*
    Script Name: Cookie Slapper
    
    Description: 
    Hands an item to the person touching the object containing
    the script and plays a slapping and a screaming sound.
    
    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.
    
    Version History:
        10/06/2025.1: Initial 
*/
// ===== Configuration section. Feel free to alter these settings ======

// Name of the sound to be played. Set to "" to turn off playing sounds
string SOUND = "slapscream";

// Volume of the sound to be played
float VOLUME = 0.5;

// name of the item to hand out. Make sure  it is copy!
string ITEM = "Rainboreo of Raveness +1";

// Probability rate at what the item should be handed out. 50% = 0.6, 100% = 1.0 
float PROBABILITY = 0.5;

// ====== Script starts here, don't change anything beyond this line =======
default
{
    state_entry() 
    {
        llSetText("", <1.0,1.0,1.0>, 0.0);
    }
    
    touch_start(integer total_number)
    {
        // tell everyone about your fail, but don't spam sim if other spank you
        if (llDetectedKey(0) == llGetOwner())
        {
            llWhisper(0, llGetDisplayName(llDetectedKey(0)) + " slaps " + llGetDisplayName(llGetOwner()));
        } else 
        {
            llOwnerSay(llGetDisplayName(llDetectedKey(0)) + " slaps " + llGetDisplayName(llGetOwner()));
        }
        
        // play a sound if sound is configured
        if (SOUND != "")llPlaySound(SOUND, VOLUME);

        // exit early if no item to hand out is sepcified
        if (ITEM == "") return;
        
        // don't give yourself cookies
        if (llDetectedKey(0) == llGetOwner()) return;
        
        // only give cookie at a certain probability 
        if (llFrand(1.) < PROBABILITY)
            llGiveInventory(llDetectedKey(0), ITEM);
    }
}
