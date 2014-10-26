FROM debian:wheezy

MAINTAINER Concerto Authors "team@concerto-signage.org"

RUN echo "deb http://ftp.us.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list

RUN apt-get update -qq && \
    apt-get -yqq install -y build-essential git-core imagemagick nodejs ruby1.9.1-full && \
    apt-get -yqq install -y libmysqlclient18 librmagick-ruby libruby1.9.1 libpq5 && \
    apt-get -yqq install -y zlib1g-dev libmagickcore-dev libmagickwand-dev libsqlite3-dev libmysqlclient-dev libpq-dev libxslt-dev libssl-dev && \
    apt-get install -y libreoffice

RUN adduser --disabled-password --home=/concerto --gecos "Concerto User" concerto && \
    mkdir /concerto/rails-root && \
    chown concerto:concerto /concerto/rails-root
COPY app /concerto/rails-root/app
COPY bin /concerto/rails-root/bin
COPY config /concerto/rails-root/config
COPY db /concerto/rails-root/db
COPY doc /concerto/rails-root/doc
COPY lib /concerto/rails-root/lib
COPY public /concerto/rails-root/public
COPY script /concerto/rails-root/script
COPY test /concerto/rails-root/test
COPY tools /concerto/rails-root/tools
COPY vendor /concerto/rails-root/vendor
COPY .git /concerto/rails-root/.git
COPY ./.gitignore /concerto/rails-root/
COPY ./.gitmodules /concerto/rails-root/
COPY ./.simplecov /concerto/rails-root/
COPY ./Gemfile /concerto/rails-root/
COPY ./Gemfile-plugins /concerto/rails-root/
COPY ./Gemfile-reporting /concerto/rails-root/
COPY ./Gemfile.lock /concerto/rails-root/
COPY ./Procfile /concerto/rails-root/
COPY ./Rakefile /concerto/rails-root/
COPY ./config.ru /concerto/rails-root/
RUN chown -R concerto /concerto/ && \
    su concerto -c "cd /concerto/rails-root/ && git submodule update --init --recursive" && \
    su concerto -c "gem install bundler --user-install" && \
    su concerto -c "cd /concerto/rails-root/ && ~/.gem/ruby/1.9.1/bin/bundle install --deployment" && \
    apt-get autoremove && \
    apt-get clean


USER concerto
VOLUME ["/concerto/rails-root/doc", "/concerto/rails-root/log", "/concerto/rails-root/tmp"]

ENTRYPOINT ["/bin/sh", "-c", "cd /concerto/rails-root && rake test"]