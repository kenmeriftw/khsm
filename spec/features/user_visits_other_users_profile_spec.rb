require 'rails_helper'

RSpec.feature 'USER visits other users profile', type: :feature do
  let(:profile_owner) { FactoryBot.create(:user) }
  let!(:games) do
    [
      FactoryBot.create(:game, user: profile_owner, current_level: 3, prize: 300, created_at: "2012-02-27 10:00:00"),
      FactoryBot.create(:game, user: profile_owner, current_level: 5, prize: 500, created_at: "2012-02-27 11:00:00",
                          finished_at: "2012-02-27 11:30:00")
    ]
  end

  scenario 'success' do
    visit user_path(profile_owner)

    expect(page).to have_content profile_owner.name
    expect(page).not_to have_content edit_user_registration_path(profile_owner)

    expect(page).to have_content '300 ₽'
    expect(page).to have_content 'в процессе'
    expect(page).to have_content '27 февр., 10:00'

    expect(page).to have_content '500 ₽'
    expect(page).to have_content 'деньги'
    expect(page).to have_content '27 февр., 11:00'
  end
end
