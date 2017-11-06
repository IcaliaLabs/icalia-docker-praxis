require 'rails_helper'

RSpec.describe Post, type: :model do
  subject { build :post }

  describe 'validations' do
    it { is_expected.to validate_presence_of :title }
    it { is_expected.to validate_presence_of :body }
  end
end
