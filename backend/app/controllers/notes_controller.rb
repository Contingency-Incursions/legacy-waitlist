# frozen_string_literal: true

class NotesController < ApplicationController

  def create
    AuthService.requires_access(@authenticated_account, "notes-add")

    if note_params[:note].length < 20 || note_params[:note].length > 5000
      render plain: 'Invalid note', status: :bad_request
      return
    end

    character_note = CharacterNote.new(
      author_id: @authenticated_account.id,
      character_id: note_params[:character_id],
      note: note_params[:note],
      logged_at: DateTime.now
    )

    if character_note.save
      render json: { status: 'OK' }
    else
      render plain: character_note.errors, status: :unprocessable_entity
    end
  end
  def index
    AuthService.requires_access(@authenticated_account, "notes-view")
    @notes = CharacterNote.joins(:author).where(character_id: params[:character_id]).select('character_note.*, character.name AS author_name').map do |note|
      {
        author: {
          id: note.author_id,
          name: note.author_name
        },
        logged_at: note.logged_at,
        note: note.note
      }
    end
    render json: { notes: @notes }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def note_params
    params.permit(:character_id, :note)
  end

end
