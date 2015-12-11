
role :web, "concerto"                   # Your HTTP server, Apache/etc
role :app, "concerto"                   # This may be the same as your `Web` server
role :db,  "concerto", primary: true    # This is where Rails migrations will run

