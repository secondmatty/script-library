/*
    Script Name: fading-slideshow.lsl
    
    Description: 
    simple slideshow script. Fades to fully transparent and back every
    time it siwtches to the next slide,
    
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

float   slide_time     =   30.0;   
float   fade_speed     =   0.01;   
integer texture_face   =   0;      


// ===== Script starts here, don't change anything beyond this line =====

list    texture_list;    
integer texture_total;   
integer texture_current; 

float a; float b;
fade_out()
{
    for (a = 10; a > 0; a--)
    {
        llSetAlpha((a/10), texture_face);
        llSleep(fade_speed);
    }

    llSetAlpha(0, texture_face);
}

fade_in()
{
    for (b = 0; b < 10; b++)
    {
        llSetAlpha((b/10), texture_face);
        llSleep(fade_speed);
    }

    llSetAlpha(1, texture_face);
}

check_for_new_textures(integer change)
{
    if(change && CHANGED_INVENTORY)
    {
        if(texture_total != llGetInventoryNumber(INVENTORY_TEXTURE))
        {
            fade_out();
            llOwnerSay("Changed textures, resetting...");
            llResetScript();
        }
    }
}

advance_texture()
{
        fade_out();
        texture_current++;
        if(texture_current > texture_total-1) texture_current=0;
        llSetTexture(llList2Key(texture_list, texture_current), texture_face);
        fade_in();
}

default
{
    state_entry()
    {
        llSetAlpha(0, texture_face);
        
        integer count = llGetInventoryNumber(INVENTORY_TEXTURE);
        string  texture_name;
        while(count--)
        {
            texture_list += llGetInventoryName(INVENTORY_TEXTURE, count);
        }
        
        texture_total = llGetListLength(texture_list);
        if(texture_total < 2)
        {
            llOwnerSay("You need at least two textures to start the slideshow!");
            return;
        }
        
        llOwnerSay("\n"
                   + "Short click to advance slides, long click to turn slideshow on/off\n"
                   + "Number of slides: " + (string)texture_total       + "\n"
                   + "Duration: "         + (string)llRound(slide_time) + " seconds");        

        texture_current = (integer) llFrand(texture_total - 1.0);
        llSetTexture(llList2Key(texture_list, texture_current), texture_face);        
        state running;
    }
    
    changed(integer change)
    {
        check_for_new_textures(change);
    }
}

state running
{
    state_entry(){
        fade_in();
        llResetTime();
        llSetTimerEvent(slide_time);
    }
    
    touch_start(integer num) { llResetTime(); }
    touch_end(integer num)
    {
        if ( llGetTime() > 0.8 ) 
        {
            llSetTimerEvent(0.0);
            state idle;
        }
        else 
        {
            llSetTimerEvent(slide_time);        
            advance_texture();
        }
    }
    
    timer()
    {
        llSetTimerEvent(slide_time);        
        advance_texture();
    }
    
    changed(integer change)
    {
        check_for_new_textures(change);
    }
}
    
state idle 
{
    state_entry()
    {
        fade_out();
    }
    
    touch_start(integer num) { llResetTime(); }
    touch_end(integer num)
    {
        if ( llGetTime() > 0.8 ) state running;
    }
    
    changed(integer change)
    {
        check_for_new_textures(change);
    }
}
