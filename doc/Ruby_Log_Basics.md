Writing statements to the log:\
In order to write statements to the log, enter this into rb files:\
Rails.logger.info "Your text here"\
Rails.logger.info "Var = #{Var_Name}"\
these statements are printed in development.log, which can be found in concerto/log\
<img width="1121" height="70" alt="{4D211B4E-7274-445A-B4C7-F063871F9BDA}" src="https://github.com/user-attachments/assets/679dc05b-de87-47e7-b3ab-d64dea21dea6" />
Clearing the log:\
In order to clear the log, delete the development.log folder from the server.\
After that, reboot the server, and a new, empty log will be created.
