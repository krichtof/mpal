FROM ruby:2.2.2

RUN apt-get update && apt-get install -y nodejs build-essential qt5-default libqt5webkit5-dev

RUN mkdir -p /app
WORKDIR /app

ADD Gemfile /app/Gemfile  
ADD Gemfile.lock /app/Gemfile.lock  
RUN bundle install

RUN gem install foreman
RUN gem install rb-readline

ADD . /app

CMD ["foreman", "start"]
