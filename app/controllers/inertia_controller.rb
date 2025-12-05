class InertiaController < ApplicationController
  inertia_share flash: -> { flash.to_hash }

  private

  def inertia_errors(model, full_messages: true)
    {
      errors: model.errors.to_hash(full_messages).transform_values(&:to_sentence)
    }
  end
end
