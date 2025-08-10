Writing statements to the log:\
In order to write statements to the log, enter this into rb files:\
Rails.logger.info "Your text here"\
Rails.logger.info "Var = #{Var_Name}"\
these statements are printed in development.log, which can be found in concerto/log\
Clearing the log:\
In order to clear the log, delete the development.log folder from the server.\
After that, reboot the server, and a new, empty log will be created.
