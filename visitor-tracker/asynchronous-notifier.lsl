/*
    Script Name: Notifier
    
    Description: 
    Sends Instant Messages to users by pulling them from the 
    messages from a messagequeue until queue is empty. 
    
    Copyright (c) 2025 Matt Briar, https://github.com/secondmatty

    This script is distributed under the MIT License. You are free
    to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the software, provided the license and
    copyright notice are included in all copies or substantial 
    portions of the software.
    
    Version History:
        10/03/2025.1: Initial 
*/

default
{
    link_message(integer sender_num, integer num, string str, key id)
    {
        // sensor told us that it has new messages in it's queue
        if (num == 0  && str=="NEW_NOTIFICATION") 
        {
            // Tell the sensor we are ready to receive a message
            llMessageLinked(LINK_THIS, 0, "GET_NOTIFICATION", "");
        }
        else if (num == 1 && str != "") 
        {
            // Received message from sensor, send it to User with id
            llInstantMessage(id, str);
            
            // Due to Linden Labs IM restrictions the script will now
            // sleep now for 2 seconds ask sensor for next message when 
            // it comes back from sleep
            llMessageLinked(LINK_THIS, 0, "GET_NOTIFICATION", "");
        }
    }
}
