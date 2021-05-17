require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для игрового контроллера
# Самые важные здесь тесты:
#   1. на авторизацию (чтобы к чужим юзерам не утекли не их данные)
#   2. на четкое выполнение самых важных сценариев (требований) приложения
#   3. на передачу граничных/неправильных данных в попытке сломать контроллер
#
RSpec.describe GamesController, type: :controller do
  # обычный пользователь
  let(:user) { FactoryBot.create(:user) }
  # админ
  let(:admin) { FactoryBot.create(:user, is_admin: true) }
  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # группа тестов для незалогиненного юзера (Анонимус)
  context 'anon user' do
    # из экшена show анона посылаем
    it 'kicked from #show' do
      # вызываем экшен
      get :show, params: { id: game_w_questions.id }
      # проверяем ответ
      expect(response.status).not_to eq(200) # статус не 200 ОК
      expect(response).to redirect_to(new_user_session_path) # devise должен отправить на логин
      expect(flash[:alert]).to be # во flash должен быть прописана ошибка
    end

    it 'kicked from #create' do
      post :create
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicked from #help' do
      put :help, params: { id: game_w_questions.id }
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicked from #answer' do
      put :answer, params: { id: game_w_questions.id }
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end

    it 'kicked from #take_money' do
      put :take_money, params: { id: game_w_questions.id }
      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to be
    end
  end

  # группа тестов на экшены контроллера, доступных залогиненным юзерам
  context 'Usual user' do
    # перед каждым тестом в группе
    before(:each) { sign_in user } # логиним юзера user с помощью спец. Devise метода sign_in

    # юзер может создать новую игру
    it 'creates game' do
      # сперва накидаем вопросов, из чего собирать новую игру
      generate_questions(15)

      post :create
      game = assigns(:game) # вытаскиваем из контроллера поле @game

      # проверяем состояние этой игры
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      # и редирект на страницу этой игры
      expect(response).to redirect_to(game_path(game))
      expect(flash[:notice]).to be
    end

    # юзер видит свою игру
    it '#show game' do
      get :show, params: { id: game_w_questions.id }
      game = assigns(:game) # вытаскиваем из контроллера поле @game
      
      expect(game.finished?).to be_falsey
      expect(game.user).to eq(user)
      expect(response.status).to eq(200) # должен быть ответ HTTP 200
      expect(response).to render_template('show') # и отрендерить шаблон show
    end

    it '#show other user game' do
      other_user_game = FactoryBot.create(:game_with_questions)
      get :show, params: { id: other_user_game.id }

      expect(response.status).not_to eq(200)
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to be
    end

    it 'takes money' do
      game_w_questions.update_attribute(:current_level, 4)
      put :take_money, params: { id: game_w_questions.id }
      game = assigns(:game)
      expect(game.finished?).to be_truthy
      expect(game.status).to eq(:money)
      expect(game.prize).to eq(500)

      user.reload
      expect(user.balance).to eq(500)

      expect(response).to redirect_to(user_path(user))
      expect(flash[:warning]).to be
    end

    it 'user can play only one game at the same time' do
      expect(game_w_questions.finished?).to be_falsey

      expect { post :create }.to change(Game, :count).by(0)

      game = assigns(:game)
      expect(game).to be_nil

      expect(response).to redirect_to(game_path(game_w_questions))
      expect(flash[:alert]).to be
    end
  end

  describe '#answer' do
    before(:each) { sign_in user }
    
    context 'when answer is correct' do
      # юзер отвечает на игру корректно - игра продолжается
      it 'the game continues' do
        # передаем параметр params[:letter]
        put :answer, params: { id: game_w_questions.id, letter: game_w_questions.current_game_question.correct_answer_key }
        game = assigns(:game)

        expect(game.finished?).to be_falsey
        expect(game.current_level).to be > 0
        expect(response).to redirect_to(game_path(game))
        expect(flash.empty?).to be_truthy # удачный ответ не заполняет flash
      end
    end
    
    context 'when answer is incorrect' do
      it 'the game fails' do
        game_w_questions.update_attribute(:current_level, 14)
        put :answer, params: { id: game_w_questions.id, letter: "e" }
        game = assigns(:game)

        expect(game.finished?).to be_truthy
        expect(game.status).to eq(:fail)
        expect(game.prize).to eq(32000)
        expect(flash[:alert]).to be
      end
    end
  end
end
