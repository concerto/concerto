Find concerto-clock.service (currently in concerto/script)\
put file under /usr/lib/systemd/system (CentOS) or /lib/systemd/system (Ubuntu)\
Run:\
systemctl enable concerto-clock\
systemctl {start,stop,restart} concerto-clock
