# Blog Application API

A Ruby on Rails-based RESTful API for a blog application with user authentication, posts, comments, and tag management.

## Features

- User authentication using JWT
- CRUD operations for posts
- Comments on posts
- Tag management for posts
- Automatic post deletion after 24 hours
- Docker-based development environment
- Comprehensive test suite

## Requirements

- Docker
- Docker Compose

## Quick Start

1. Clone the repository
2. Run the application:
   ```bash
   docker-compose up
   ```
3. The API will be available at `http://localhost:3000`

## API Endpoints

### Authentication
- POST `/api/v1/register` - Register a new user
- POST `/api/v1/login` - Login and receive JWT token

### Posts
- GET `/api/v1/posts` - List all posts
- GET `/api/v1/posts/:id` - Get a specific post
- POST `/api/v1/posts` - Create a new post
- PUT `/api/v1/posts/:id` - Update a post
- DELETE `/api/v1/posts/:id` - Delete a post

### Comments
- POST `/api/v1/posts/:post_id/comments` - Create a comment
- PUT `/api/v1/posts/:post_id/comments/:id` - Update a comment
- DELETE `/api/v1/posts/:post_id/comments/:id` - Delete a comment

### Tags
- GET `/api/v1/tags` - List all tags
- POST `/api/v1/tags` - Create a new tag
- PUT `/api/v1/tags/:id` - Update a tag
- DELETE `/api/v1/tags/:id` - Delete a tag

## Authentication

All API endpoints except registration and login require JWT authentication. Include the JWT token in the Authorization header:

```
Authorization: Bearer <token>
```

## Development

The application uses:
- PostgreSQL for the database
- Redis for Sidekiq background jobs
- Sidekiq for processing background jobs (post deletion)

### Running Tests

```bash
docker-compose run web bundle exec rspec
```

## Sample Data

The application includes seed data for testing. After starting the application, you can log in with:

- Email: john@example.com
- Password: password123

or

- Email: jane@example.com
- Password: password123
