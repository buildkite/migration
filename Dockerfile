FROM ruby:3.2

ENV RACK_ENV=production

WORKDIR /app
COPY app/Gemfile* ./
RUN bundle install

COPY app /app

RUN ln -s /app/bin/buildkite-compat /bin/buildkite-compat

ENTRYPOINT "/bin/bash"
CMD [ "buildkite-compat" ]