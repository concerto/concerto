Refreshing basics in concerto:\
All data types that require refreshing(RSS feeds, Calendars, and Weather as of writing) are subclasses of Dynamic Content.\
In order for Dynamic Content to be refreshed, cron.rb must submit the 'Refresh Dynamic Content' task to the delayed task tool, which is then run by the rake.\
In order for this to work, concerto-clock.service and concerto-worker.service must both be running on the desired server.\
To check if these files are installed properly, run the following commands: \
systemctl status concerto-clock.service\
<img width="1852" height="269" alt="{696DEA9F-0DBD-420E-8509-5AD8A6045CE8}" src="https://github.com/user-attachments/assets/5907a1b6-05fa-4a48-a7c6-780160b979a4" />

systemctl status concerto-worker.service\
<img width="1698" height="265" alt="{3F0CEAD9-2D03-42C2-99C2-D7CCD71CD479}" src="https://github.com/user-attachments/assets/b43e294d-3232-49cc-bd23-c962639b4cbe" />

If these lines don't run properly, check the services files to make sure that they are installed properly.\
If edits need to be made to the files themselves, make sure to run systemctl daemon-reload after making them. Otherwise, the server won't acknowledge the change.\
If these services are running, but refreshing still isn't working, check dynamic_content.rb.
(Note: there are 2 .refresh() functions in dynamic_content.rb. The one that cron.rb is calling is self.refresh())

Manual refreshing:\
If auto-refreshing doesn't seem to be working, check to see if manual refreshing is working.\
To manually refresh an item in concerto, click on it, go to edit, and then submit it again. After this, you should have the option to "Force Update", which should manually refresh the element.


