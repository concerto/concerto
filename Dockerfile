FROM debian:wheezy

MAINTAINER Concerto Authors "team@concerto-signage.org"

RUN echo "deb http://ftp.us.debian.org/debian wheezy-backports main" >> /etc/apt/sources.list

RUN apt-get update -qq && \
    apt-get -yqq install -y build-essential git-core imagemagick nodejs ruby1.9.1-full && \
    apt-get -yqq install -y libmysqlclient18 librmagick-ruby libruby1.9.1 libpq5 && \
    apt-get -yqq install -y zlib1g-dev libmagickcore-dev libmagickwand-dev libsqlite3-dev libmysqlclient-dev libpq-dev libxslt-dev libssl-dev && \
    apt-get install -y libreoffice && \
    gem install bundler

RUN adduser --disabled-password --home=/concerto --gecos "Concerto User" concerto && \
    mkdir /concerto/rails-root && chown concerto:concerto /concerto/rails-root
ADD app /concerto/rails-root
ADD bin /concerto/rails-root
ADD config /concerto/rails-root
ADD db /concerto/rails-root
ADD doc /concerto/rails-root
ADD lib /concerto/rails-root
ADD public /concerto/rails-root
ADD script /concerto/rails-root
ADD test /concerto/rails-root
ADD tools /concerto/rails-root
ADD vendor /concerto/rails-root
ADD .git /concerto/rails-root
ADD .gitignore /concerto/rails-root/
ADD .gitmodules /concerto/rails-root/
ADD .simplecov /concerto/rails-root/
ADD Gemfile /concerto/rails-root/
ADD Gemfile-plugins /concerto/rails-root/
ADD Gemfile-reporting /concerto/rails-root/
ADD Gemfile.lock /concerto/rails-root/
ADD Procfile /concerto/rails-root/
ADD Rakefile /concerto/rails-root/
ADD config.ru /concerto/rails-root/
RUN su concerto -c "cd /concerto/rails-root/ && git submodule update --init --recursive && bundle install" && \
    apt-get autoremove && \
    apt-get clean

USER concerto
VOLUME ["/concerto/rails-root/doc", "/concerto/rails-root/log", "/concerto/rails-root/tmp"]

ENTRYPOINT ["/bin/sh", "-c", "cd /concerto/rails-root && rake test"]