FROM ruby:3.2

ENV RACK_ENV=production

WORKDIR /app
COPY app /app
RUN bundle install

RUN ln -s /app/bin/buildkite-compat /bin/buildkite-compat