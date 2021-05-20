require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let(:user) { FactoryBot.create :user }

  before(:each) do
    assign(:user, user)
    assign(:games, [
      FactoryBot.build_stubbed(:game, id: 1, current_level: 3, prize: 300)
    ])

    render
  end

  context 'user == current_user' do
    before(:each) do 
      sign_in user
      render
    end

    it 'renders users name' do
      expect(rendered).to match user.name
    end

    it 'renders psswd chng link' do
      expect(rendered).to match edit_user_registration_path(user)
    end

    it 'render games' do
      expect(rendered).to match '3'
      expect(rendered).to match '300 ₽'
    end
  end

  context 'user != current_user' do
    it 'renders users name' do
      expect(rendered).to match user.name
    end

    it 'not renders psswd chng link' do
      expect(rendered).not_to match edit_user_registration_path(user)
    end

    it 'render games' do
      expect(rendered).to match '3'
      expect(rendered).to match '300 ₽'
    end
  end
end
