Refreshing basics in concerto:
Some data types, including all data types that use refreshing, are stored in concerto as Dynamic Content.
Dynamic Content seems to be both a data type, and an operating file.
The heart of refreshing content is cron.rb, which can be found here:concerto/lib/cron.rb
This file contains the clockwork module, which is Concertos method for occasionally running the refresh method.
This is not the same as clock.rb, and one can be running while the other doesn't.
IF CRON.RB DOESN'T SEEM TO BE RUNNING:
Check the clockwork installation file for instructions on running the related service file.

Cron.rb calls DynamicContent.delay.refresh every 5 minutes.
.delay seems to put the refresh function in a queue(couldn't find much info on this)
NOTE: this calls the self.refresh() function, not the refresh() function.
.refresh retrieves all content from the server, and filters it down to the dynamic content. I then runs the refresh() function on all elements of dynamic content.
The refresh() function checks if a refresh is needed(seeing if the neccessary time has elapsed). If one is, it runs the refresh! function.
the refresh! function immediately updates the last refresh attempt value. It then updates the dynamic content.

Manual refreshing:
If auto-refreshing doesn't seem to be working, check to see if manual refreshing is working.
To manually refresh an item in concerto, click on it, go to edit, and then submit it again. After this, you should have the option to "Force Update", which should manually refresh the element.
If manual refreshing works, but auto refreshing doesn't, check to see if concerto-clock.service and concerto-worker.service are still running.
