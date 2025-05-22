FactoryBot.define do
  factory :post do
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph(sentence_count: 3) }
    user

    after(:build) do |post|
      post.tags << build(:tag) if post.tags.empty?
    end
  end
end