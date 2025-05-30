FROM ruby:2.6.5-alpine@sha256:a5b974e2ebb2b72642f4de4e5562597ec0883c3bfd93e9553cee6bd395dfbf00
RUN mkdir /timdex
WORKDIR /timdex
COPY Gemfile /timdex/Gemfile
COPY Gemfile.lock /timdex/Gemfile.lock

RUN apk add --no-cache build-base sqlite-dev nodejs tzdata bash
RUN gem install bundler:2.0.2
RUN bundle install --without production

COPY . /timdex

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
