# frozen_string_literal: true

module RuboCop
  module Cop
    module Inertia
      # Requires `.as_json` calls to specify the `only:` parameter.
      #
      # Calling `.as_json` without `only:` serializes all model attributes,
      # which can accidentally expose sensitive data to the frontend.
      #
      # @example
      #   # bad
      #   @item.as_json
      #   Item.all.as_json
      #   @item.as_json(include: :author)
      #
      #   # good
      #   @item.as_json(only: %i[id name])
      #   Item.all.as_json(only: %i[id name created_at])
      #   @item.as_json(only: %i[id name], include: { author: { only: %i[id name] } })
      #
      class AsJsonRequiresOnly < Base
        MSG = "Specify `only:` parameter in `.as_json` to prevent accidentally exposing sensitive data."

        RESTRICT_ON_SEND = [ :as_json ].freeze

        def_node_matcher :as_json_with_only?, <<~PATTERN
          (send _ :as_json (hash <(pair (sym :only) _) ...>))
        PATTERN

        def_node_matcher :as_json_call?, <<~PATTERN
          (send _ :as_json ...)
        PATTERN

        def on_send(node)
          return unless as_json_call?(node)
          return if as_json_with_only?(node)
          return unless in_controller?(node)

          add_offense(node)
        end

        private

        def in_controller?(node)
          node.each_ancestor(:class).any? do |class_node|
            class_name = class_node.identifier.const_name
            class_name&.end_with?("Controller")
          end
        end
      end
    end
  end
end
