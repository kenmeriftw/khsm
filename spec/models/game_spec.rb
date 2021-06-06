require 'rails_helper'
require 'support/my_spec_helper'

RSpec.describe Game, type: :model do
  let(:user) { FactoryBot.create(:user) }

  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user)}

  context 'Game Factory' do
    it 'Game.create_game_for_user! new correct game' do 
      generate_questions(60)

      game = nil
      expect { game = Game.create_game_for_user!(user) }.to change(Game, :count).by(1)
        .and(change(GameQuestion, :count).by(15))

      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)

      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end

  context 'game mechanics' do 
    let(:level) { game_w_questions.current_level }

    it 'answer correct continues' do
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      expect(game_w_questions.current_level).to eq(level + 1)

      expect(game_w_questions.previous_game_question).to eq q
      expect(game_w_questions.current_game_question).not_to eq q

      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be false
    end

    it 'correct .take_money' do
      q = game_w_questions.current_game_question
      game_w_questions.answer_current_question!(q.correct_answer_key)
      game_w_questions.take_money!

      expect(game_w_questions.status).to eq(:money)
      expect(game_w_questions.finished?).to be true
      expect(user.balance).to eq (game_w_questions.prize)
    end

    it 'correct .current_game_question method' do
      expect(game_w_questions.current_game_question.level).to eq(level)
    end

    it 'correct .previous_level method' do
      expect(game_w_questions.previous_level).to eq(level - 1)
    end
  end

  describe '#answer_current_question!' do
    let(:q) { game_w_questions.current_game_question }

    context 'when answer is wrong' do
      let(:wrong_answer_key) do 
        %i[a b c d].reject { |e| e == game_w_questions.current_game_question.correct_answer_key }.sample 
      end

      before { game_w_questions.answer_current_question!(wrong_answer_key) }

      it 'should finish game with status fail' do
        expect(game_w_questions.finished?).to be true
        expect(game_w_questions.status).to eq(:fail)
        expect(user.balance).to eq(0)
      end
    end

    context 'when answer is correct' do
      let!(:level) { game_w_questions.current_level }
      let!(:correct_answer_key) { q.correct_answer_key }

      before { game_w_questions.answer_current_question!(correct_answer_key) }

      context 'and question is last' do
        let(:level) { Question::QUESTION_LEVELS.max }
        let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user, current_level: level) }

        before { game_w_questions.answer_current_question!(correct_answer_key) }

        it 'should assign final prize' do
          expect(user.balance).to eq(Game::PRIZES[level])
        end

        it 'should finish game with status won' do
          expect(game_w_questions.finished?).to be true
          expect(game_w_questions.status).to eq(:won)
        end
      end

      context 'and question is not last' do
        it 'should increase the current level by 1' do
          expect(game_w_questions.current_level).to eq(level + 1)
        end

        it 'should continue game' do
        expect(game_w_questions.finished?).to be false
        expect(game_w_questions.status).to eq(:in_progress)
        end
      end

      context 'and time is out ' do
        let(:game_w_questions) { FactoryBot.create(:game_with_questions, created_at: 36.minutes.ago) }

        it 'should finish game with status timeout' do
          expect(game_w_questions.finished?).to be true
          expect(game_w_questions.status).to eq(:timeout)
        end
      end
    end
  end

  context '.status' do
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be true
    end

    it 'correct :won status' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it 'correct :fail status' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it 'correct :money status' do
      expect(game_w_questions.status).to eq(:money)
    end

    it 'correct :timeout status' do
      game_w_questions.created_at = 36.minutes.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end
  end
end
