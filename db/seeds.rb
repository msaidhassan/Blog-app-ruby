# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create admin user
puts "Creating admin user..."
admin = User.create!(
  name: "Admin User",
  email: "admin@example.com",
  password: "admin123",
  admin: true
)

# Create regular users
puts "Creating regular users..."
user1 = User.create!(
  name: "John Doe",
  email: "john@example.com",
  password: "password123",
  admin: false
)

user2 = User.create!(
  name: "Jane Smith",
  email: "jane@example.com",
  password: "password123",
  admin: false
)

# Create sample tags
puts "Creating tags..."
tags = ["ruby", "rails", "api", "web", "programming", "development"].map do |name|
  Tag.create!(name: name)
end

# Create sample posts
puts "Creating posts..."
post1 = user1.posts.create!(
  title: "Getting Started with Ruby on Rails",
  body: "Ruby on Rails is a web application framework that includes everything needed to create database-backed web applications according to the Model-View-Controller (MVC) pattern...",
  tag_ids: [tags[0].id, tags[1].id] # Assign tags directly during creation
)

post2 = user2.posts.create!(
  title: "RESTful API Design Best Practices",
  body: "When designing RESTful APIs, it's important to follow established conventions and best practices...",
  tag_ids: [tags[2].id, tags[3].id] # Assign tags directly during creation
)

# Create sample comments
puts "Creating comments..."
post1.comments.create!(
  body: "Great introduction to Rails!",
  user: user2
)

post2.comments.create!(
  body: "Very helpful article about API design.",
  user: user1
)

puts "Seed data created successfully!"
