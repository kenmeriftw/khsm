require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  before(:each) do
    assign(:user,
      FactoryBot.build_stubbed(:user, name: 'Борис', balance: 5000))

    render
    end


  it 'renders player name' do

  end

  it 'renders psswd chng button for current_user' do
  end

  it 'renders game parts' do
  end
end
