FROM rails6:latest
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . /app