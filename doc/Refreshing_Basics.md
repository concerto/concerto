Refreshing basics in concerto:\
All data types that require refreshing(RSS feeds, Calendars, and Weather as of writing) are subclasses of Dynamic Content.\
In order for Dynamic Content to be refreshed, cron.rb must submit the 'Refresh Dynamic Content' task to the delayed task tool, which is then run by the rake.\
In order for this to work, concerto-clock.service and concerto-worker.service must both be running on the desired server.\
To check if these files are installed properly, run the following commands: \
systemctl status concerto-clock.service\
systemctl status concerto-worker.service\
If these lines don't run properly, check the services files to make sure that they are installed properly.\
If edits need to be made to the files themselves, make sure to run systemctl daemon-reload after making them. Otherwise, the server won't acknowledge the change.\
If these services are running, but refreshing still isn't working, check dynamic_content.rb.
(Note: there are 2 .refresh() functions in dynamic_content.rb. The one that cron.rb is calling is self.refresh())

Manual refreshing:\
If auto-refreshing doesn't seem to be working, check to see if manual refreshing is working.\
To manually refresh an item in concerto, click on it, go to edit, and then submit it again. After this, you should have the option to "Force Update", which should manually refresh the element.
