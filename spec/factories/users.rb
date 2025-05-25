FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    admin { false }

    trait :admin do
      admin { true }
    end
  end
end