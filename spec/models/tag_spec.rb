require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
  end

  describe 'associations' do
    it { should have_many(:post_tags).dependent(:destroy) }
    it { should have_many(:posts).through(:post_tags) }
  end

  describe 'callbacks' do
    it 'downcases the name before saving' do
      tag = Tag.create(name: 'RUBY')
      expect(tag.name).to eq('ruby')
    end
  end
end
