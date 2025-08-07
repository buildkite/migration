# If this gets updated, update pipeline images and .ruby-version
FROM ruby:3.4.5

ENV RACK_ENV=production

WORKDIR /app
COPY app/Gemfile* ./
RUN bundle install

COPY app /app

RUN ln -s /app/bin/buildkite-compat /bin/buildkite-compat

WORKDIR /
ENTRYPOINT [ "buildkite-compat" ]
