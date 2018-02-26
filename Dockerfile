FROM ruby:2.3
RUN apt-get update -qq && apt-get install -y build-essential
#RUN groupadd -g 999 appuser && \
#    useradd -r -u 999 -g appuser appuser
#RUN mkdir /app \
#  && chgrp appuser /app \
#  && chmod g+rwX /app
#USER appuser
RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle config --local path /app/.gems
COPY . /app
