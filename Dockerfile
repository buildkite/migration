FROM ruby:3.2

WORKDIR /app
COPY app/Gemfile* ./
RUN bundle install

COPY app /app

RUN ln -s /app/bin/buildkite-compat /bin/buildkite-compat

WORKDIR /
ENTRYPOINT [ "buildkite-compat" ]