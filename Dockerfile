FROM ruby:2.3
RUN apt-get update -qq && apt-get install -y build-essential
RUN mkdir /app
WORKDIR /app
#COPY Gemfile /app/Gemfile
#COPY Gemfile.lock /app/Gemfile.lock
COPY . /app
RUN bundle install