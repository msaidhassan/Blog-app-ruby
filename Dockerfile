# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t blog_app_ruby .
# docker run -d -p 3000:3000 -e RAILS_MASTER_KEY=<value from config/master.key> --name blog_app_ruby blog_app_ruby

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

FROM ruby:3.2-slim

# Install essential Linux packages
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    git \
    nodejs \
    netcat-traditional \
    imagemagick \
    libvips \
    libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the application code
COPY . .

# Create storage directory for Active Storage
RUN mkdir -p tmp/storage

# Add a script to be executed every time the container starts
COPY bin/web-entrypoint bin/sidekiq-entrypoint /usr/bin/
RUN chmod +x /usr/bin/web-entrypoint /usr/bin/sidekiq-entrypoint
ENTRYPOINT ["docker-entrypoint"]

# Configure the main process to run when running the image
EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
