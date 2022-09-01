FROM ruby:3.0

COPY scripts /scripts

RUN chmod +x /scripts/main.rb

ENV TZ="Europe/Amsterdam"

ENTRYPOINT ["ruby", "/scripts/main.rb"]
