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
admin = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Admin User"
  user.password = "admin123"
  user.admin = true
end

# Create regular users
puts "Creating regular users..."
user1 = User.find_or_create_by!(email: "john@example.com") do |user|
  user.name = "John Doe"  
  user.password = "password123"
  user.admin = false
end

user2 = User.find_or_create_by!(email: "jane@example.com") do |user|
  user.name = "Jane Smith"
  user.password = "password123"
  user.admin = false
end

# Create sample tags
puts "Creating tags..."
tags = ["ruby", "rails", "api", "web", "programming", "development"].map do |name|
  Tag.find_or_create_by!(name: name)
end

# Create sample posts
puts "Creating posts..."
post1 = Post.find_or_create_by!(title: "Getting Started with Ruby on Rails") do |post|
  post.user = user1
  post.body = "Ruby on Rails is a web application framework that includes everything needed to create database-backed web applications according to the Model-View-Controller (MVC) pattern..."
  post.tags = [tags[0], tags[1]]
end

post2 = Post.find_or_create_by!(title: "RESTful API Design Best Practices") do |post|
  post.user = user2
  post.body = "When designing RESTful APIs, it's important to follow established conventions and best practices..."
  post.tags = [tags[2], tags[3]]
end

# Create sample comments
puts "Creating comments..."
Comment.find_or_create_by!(post: post1, user: user2) do |comment|
  comment.body = "Great introduction to Rails!"
end

Comment.find_or_create_by!(post: post2, user: user1) do |comment|
  comment.body = "Very helpful article about API design."
end

puts "Seed data created successfully!"
