/*
    Script Name: Floating Cube
    
    Description: 
    Let's a glowing cube appear in your hand. The scripts listens
    on channel 5 for "show" and "hide" commands. The cube has no
    touch events, so it is perfect for adding your own interactive
    elements to it.
    
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

// Command Chat Channel
integer CHANNEL = 5;

// RGB Color for light and texture
float R = 1.0;
float G = 1.0;
float B = 1.0;

// global cube ALPHA value
float ALPHA;

// Animation to play while the cube is visible
string ANIM="standing";


// ====== Script starts here, don't change anything beyond this line =======

// state order:
// default -> show_anim -> show_cube -> visible -> hide -> show_anim -> show_cube -> visible ....
default
{   
    // reset script if cube is attached
    on_rez(integer start_param)
    {
        llResetScript();
    }

    // throw welcome message and setup permissions
    state_entry()
    {
        string welcome_message = "Welcome to Matt's Calendar Cube.";

        llOwnerSay(welcome_message);
        
        // turn off light and glow, hide cube
        ALPHA=0.0;
        llSetColor(<R,G,B>,ALL_SIDES);
        llSetPrimitiveParams ([PRIM_POINT_LIGHT, TRUE, <R, G, B>, ALPHA, 5.0, 0.75]);
        llSetPrimitiveParams ([PRIM_GLOW, ALL_SIDES, 0.0]);
        llSetAlpha(0.0, ALL_SIDES);
        
        // request permissions to animate avatar
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
    }

    run_time_permissions(integer perm)
    { 
        if (perm & PERMISSION_TRIGGER_ANIMATION) 
        {
            llListen(CHANNEL, "", llGetOwner(), "show");
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (llToLower(message)=="show") state show_anim;
    }
}


state visible
{
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        llListen(CHANNEL, "", llGetOwner(), "hide");
        // llTargetOmega(<1.0,1.0,1.0>,1.0,1.0);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (llToLower(message)=="hide")    state hide;
    }
}

state hide
{
    state_entry()
    {
        // stop cube rotation, disable glow and setup timer to fade out the cube
        // llTargetOmega(<0.0,0.0,0.0>,0.0,0.0);
        llSetPrimitiveParams ([PRIM_GLOW, ALL_SIDES, 0.0]);
        llSetTimerEvent(0.1);
    }

    // reset if cube is attached while in this state
    on_rez(integer start_param)
    {
        llResetScript();
    }
            
    timer()
    {
        // decrease ALPHA by 0.3 every 0.1 seconds while it's higher then 0.0
        if (ALPHA > 0.0)
        {
            ALPHA=ALPHA-0.3;
            llSetAlpha(ALPHA, ALL_SIDES);
            llSetPrimitiveParams ([PRIM_POINT_LIGHT, TRUE, <R, G, B>, ALPHA, 5.0, 0.75]);
        } else
        {
            // due to the float type it eventually will never hit 0.0 exactly. 
            // catch this exception and set it explicitly to 0.0, hide the cube,
            // stop the anaimation and wait for further orders
            llSetTimerEvent(0);
            ALPHA=0.0;
            llSetAlpha(0.0, ALL_SIDES);
            llSetPrimitiveParams ([PRIM_POINT_LIGHT, TRUE, <R, G, B>, 0.0, 5.0, 0.75]);
            llStopAnimation(ANIM);
            llListen(CHANNEL, "", llGetOwner(), "show");
        }
    } 
    
    listen(integer channel, string name, key id, string message)
    {
        // switch to show_anim state if owner says "show"
        if (llToLower(message)=="show")
        {
            state show_anim;
        }
    }
    
}

state show_anim
{
    state_entry()
    {
        // start animation and setup timer to switch to next state after 1.5 seconds
        llSetTimerEvent(1.5);
        llStartAnimation(ANIM);
    }

    // reset if cube is attached while in this state
    on_rez(integer start_param)
    {
        llResetScript();
    }
    
    timer()
    {
        // time is over, the animation should be done now. 
        // Disable timer and switch to next state
        llSetTimerEvent(0);
        state show_cube;
    }    
}


state show_cube
{
    state_entry()
    {
        // setup timer and activate glow
        llSetTimerEvent(0.1);
        llSetPrimitiveParams ([PRIM_GLOW, ALL_SIDES, 0.1]);
    }
    
    // reset if cube is attached while in this state
    on_rez(integer start_param)
    {
        llResetScript();
    }
    
    timer()
    { 
        // fade-in the cube. +0.3 ALPHA level every 0.1 seconds while it is below 1.0
        if (ALPHA < 1.0)
        {
            ALPHA=ALPHA+0.3;
            llSetAlpha(ALPHA, ALL_SIDES);            
            llSetPrimitiveParams ([PRIM_POINT_LIGHT, TRUE, <R, G, B>, ALPHA, 5.0, 0.75]);
        } else
        {
            // the lower then 1.0 and else construct is neccessary because float is not
            // precise and will probably not hit 1.0 exactly
            ALPHA=1.0;
            llSetPrimitiveParams ([PRIM_POINT_LIGHT, TRUE, <R, G, B>, 1.0, 5.0, 0.75]);
            llSetAlpha(1.0, ALL_SIDES);
        
            // the cube is visible, switch to state visible
            state visible;
        }
    } 
}

